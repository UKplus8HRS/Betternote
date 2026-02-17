import Foundation
import CloudKit
import Combine

/// CloudKit 管理器
/// 负责 iCloud 数据同步
/// 
/// 功能：
/// - 笔记本和页面的 CRUD 操作
/// - 离线支持 (本地缓存 + 在线同步)
/// - 冲突解决
final class CloudKitManager: ObservableObject {
    
    // MARK: - 属性
    
    /// CloudKit 容器
    private let container: CKContainer
    
    /// 数据库 (私有数据库，用于用户个人数据)
    private let privateDatabase: CKDatabase
    
    /// 是否正在同步
    @Published var isSyncing: Bool = false
    
    /// 最后同步时间
    @Published var lastSyncDate: Date?
    
    /// 同步错误
    @Published var syncError: Error?
    
    /// 订阅ID
    private var subscriptionID: CKSubscription.ID?
    
    // MARK: - 初始化
    
    init() {
        self.container = CKContainer(identifier: "iCloud.com.yourteam.ClawNotes")
        self.privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - 公开方法
    
    /// 检查 iCloud 账户状态
    /// - Returns: 账户状态
    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            print("检查 iCloud 账户状态失败: \(error)")
            return .couldNotDetermine
        }
    }
    
    /// 保存笔记本到 iCloud (包含所有页面)
    /// - Parameter notebook: 笔记本实例
    /// - Returns: 保存成功返回更新后的记录，失败返回 nil
    @discardableResult
    func saveNotebook(_ notebook: Notebook) async throws -> CKRecord? {
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. 准备笔记本记录
        let notebookRecord = notebook.toRecord()
        var recordsToSave = [notebookRecord]
        
        // 2. 准备页面记录
        let pageRecords = notebook.pages.map { $0.toCKRecord(notebookID: notebookRecord.recordID) }
        recordsToSave.append(contentsOf: pageRecords)
        
        return try await withCheckedThrowingContinuation { continuation in
            // 3. 批量保存操作
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            operation.isAtomic = true // 原子操作：要么全成功，要么全失败
            
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                    }
                    continuation.resume(returning: notebookRecord)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.syncError = error
                    }
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    /// 从 iCloud 获取所有笔记本 (包含页面)
    /// - Returns: 笔记本数组
    func fetchAllNotebooks() async throws -> [Notebook] {
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. 获取所有笔记本记录
        let query = CKQuery(recordType: Notebook.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        var notebooks: [Notebook] = []
        
        // 2. 并发获取每个笔记本的页面
        try await withThrowingTaskGroup(of: Notebook?.self) { group in
            for (_, result) in matchResults {
                if case .success(let record) = result,
                   var notebook = Notebook.from(record: record) {
                    
                    group.addTask {
                        // 获取该笔记本的页面
                        let pages = try await self.fetchPages(for: notebook.id)
                        notebook.pages = pages
                        return notebook
                    }
                }
            }
            
            for try await notebook in group {
                if let notebook = notebook {
                    notebooks.append(notebook)
                }
            }
        }
        
        // 3. 排序 (因为并发会导致乱序)
        notebooks.sort { $0.modifiedAt > $1.modifiedAt }
        
        lastSyncDate = Date()
        return notebooks
    }
    
    /// 获取特定笔记本的页面
    private func fetchPages(for notebookID: UUID) async throws -> [NotePage] {
        let notebookRecordID = CKRecord.ID(recordName: notebookID.uuidString)
        let parentReference = CKReference(recordID: notebookRecordID, action: .none)
        
        let predicate = NSPredicate(format: "notebook == %@", parentReference)
        let query = CKQuery(recordType: "NotePage", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)] // 按创建时间排序
        
        // 注意：如果页面很多，可能需要游标 (Cursor) 分页，这里简化为获取最多 100 页
        // 实际项目应处理 cursor
        let (matchResults, _) = try await privateDatabase.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100)
        
        var pages: [NotePage] = []
        for (_, result) in matchResults {
            if case .success(let record) = result,
               let page = NotePage(record: record) {
                pages.append(page)
            }
        }
        
        return pages
    }
    
    /// 删除笔记本
    /// - Parameter notebookID: 笔记本 ID
    func deleteNotebook(_ notebookID: UUID) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // 级联删除：删除 Notebook 记录会自动删除关联的 Page 记录 (得益于 CKReference action: .deleteSelf)
        let recordID = CKRecord.ID(recordName: notebookID.uuidString)
        
        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            lastSyncDate = Date()
        } catch {
            syncError = error
            throw error
        }
    }
    
    /// 订阅笔记本变化通知
    /// 用于多设备实时同步
    func subscribeToNotebookChanges() async throws {
        let subscription = CKQuerySubscription(
            recordType: Notebook.recordType,
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            subscriptionID = savedSubscription.subscriptionID
        } catch {
            print("订阅失败: \(error)")
            throw error
        }
    }
}
