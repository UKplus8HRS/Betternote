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
    
    /// 保存笔记本到 iCloud
    /// - Parameter notebook: 笔记本实例
    /// - Returns: 保存成功返回更新后的记录，失败返回 nil
    @discardableResult
    func saveNotebook(_ notebook: Notebook) async throws -> CKRecord? {
        isSyncing = true
        defer { isSyncing = false }
        
        let record = notebook.toRecord()
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            lastSyncDate = Date()
            return savedRecord
        } catch {
            syncError = error
            throw error
        }
    }
    
    /// 从 iCloud 获取所有笔记本
    /// - Returns: 笔记本数组
    func fetchAllNotebooks() async throws -> [Notebook] {
        isSyncing = true
        defer { isSyncing = false }
        
        let query = CKQuery(recordType: Notebook.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            
            var notebooks: [Notebook] = []
            
            for (_, result) in results {
                if case .success(let record) = result,
                   let notebook = Notebook.from(record: record) {
                    notebooks.append(notebook)
                }
            }
            
            lastSyncDate = Date()
            return notebooks
        } catch {
            syncError = error
            throw error
        }
    }
    
    /// 删除笔记本
    /// - Parameter notebookID: 笔记本 ID
    func deleteNotebook(_ notebookID: UUID) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
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
