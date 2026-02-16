import Foundation
import Combine

/// 离线数据管理器
/// 负责本地缓存和离线支持
final class OfflineManager: ObservableObject {
    
    // MARK: - Published 属性
    
    /// 是否处于离线状态
    @Published var isOffline: Bool = false
    
    /// 等待同步的更改数量
    @Published var pendingChangesCount: Int = 0
    
    // MARK: - 私有属性
    
    private let userDefaults = UserDefaults.standard
    private let pendingChangesKey = "com.clawnotes.pendingChanges"
    
    // MARK: - 待同步的更改
    
    /// 待同步的更改类型
    enum ChangeType: String, Codable {
        case create
        case update
        case delete
    }
    
    /// 待同步的更改
    struct PendingChange: Codable, Identifiable {
        let id: UUID
        let type: ChangeType
        let entityType: String  // "notebook" 或 "page"
        let entityId: UUID
        let timestamp: Date
        let data: Data?
    }
    
    // MARK: - 方法
    
    /// 添加待同步的更改
    func addPendingChange(_ change: PendingChange) {
        var changes = loadPendingChanges()
        changes.append(change)
        savePendingChanges(changes)
        pendingChangesCount = changes.count
    }
    
    /// 移除已同步的更改
    func removePendingChange(id: UUID) {
        var changes = loadPendingChanges()
        changes.removeAll { $0.id == id }
        savePendingChanges(changes)
        pendingChangesCount = changes.count
    }
    
    /// 获取所有待同步的更改
    func getPendingChanges() -> [PendingChange] {
        return loadPendingChanges()
    }
    
    /// 清除所有待同步的更改
    func clearPendingChanges() {
        savePendingChanges([])
        pendingChangesCount = 0
    }
    
    // MARK: - 私有方法
    
    private func loadPendingChanges() -> [PendingChange] {
        guard let data = userDefaults.data(forKey: pendingChangesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([PendingChange].self, from: data)
        } catch {
            print("加载待同步更改失败: \(error)")
            return []
        }
    }
    
    private func savePendingChanges(_ changes: [PendingChange]) {
        do {
            let data = try JSONEncoder().encode(changes)
            userDefaults.set(data, forKey: pendingChangesKey)
        } catch {
            print("保存待同步更改失败: \(error)")
        }
    }
}

// MARK: - 同步冲突解决

/// 冲突解决策略
enum ConflictResolutionStrategy {
    case localWins      // 本地优先
    case remoteWins     // 远程优先
    case newestWins     // 最新优先
    case manual         // 手动选择
}

/// 冲突信息
struct SyncConflict {
    let entityId: UUID
    let entityType: String
    let localData: Any?
    let remoteData: Any?
    let localModifiedAt: Date
    let remoteModifiedAt: Date
    
    /// 获取最新版本
    func newest() -> Any? {
        return remoteModifiedAt > localModifiedAt ? remoteData : localData
    }
}

/// 同步管理器
final class SyncManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncError: Error?
    @Published var conflictResolution: ConflictResolutionStrategy = .newestWins
    
    // MARK: - 私有属性
    
    private let cloudKitManager: CloudKitManager
    private let offlineManager: OfflineManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    init(cloudKitManager: CloudKitManager, offlineManager: OfflineManager) {
        self.cloudKitManager = cloudKitManager
        self.offlineManager = offlineManager
    }
    
    // MARK: - 同步方法
    
    /// 执行完整同步
    func sync() async {
        guard !isSyncing else { return }
        
        await MainActor.run { isSyncing = true }
        
        do {
            // 1. 上传本地更改
            try await uploadPendingChanges()
            
            // 2. 下载远程更改
            try await downloadRemoteChanges()
            
            await MainActor.run {
                lastSyncTime = Date()
                syncError = nil
            }
        } catch {
            await MainActor.run {
                syncError = error
            }
        }
        
        await MainActor.run { isSyncing = false }
    }
    
    /// 上传待同步的更改
    private func uploadPendingChanges() async throws {
        let pendingChanges = offlineManager.getPendingChanges()
        
        for change in pendingChanges {
            do {
                switch change.entityType {
                case "notebook":
                    try await uploadNotebookChange(change)
                case "page":
                    try await uploadPageChange(change)
                default:
                    break
                }
                
                // 成功上传，移除待同步记录
                offlineManager.removePendingChange(id: change.id)
            } catch {
                print("上传更改失败: \(error)")
                // 继续处理下一个
            }
        }
    }
    
    /// 上传笔记本更改
    private func uploadNotebookChange(_ change: PendingChange) async throws {
        // 实现笔记本上传逻辑
    }
    
    /// 上传页面更改
    private func uploadPageChange(_ change: PendingChange) async throws {
        // 实现页面上传逻辑
    }
    
    /// 下载远程更改
    private func downloadRemoteChanges() async throws {
        // 实现远程更改下载逻辑
    }
    
    // MARK: - 冲突检测
    
    /// 检测冲突
    func detectConflict(local: Any, remote: Any, localModifiedAt: Date, remoteModifiedAt: Date) -> SyncConflict? {
        guard localModifiedAt != remoteModifiedAt else {
            return nil
        }
        
        return SyncConflict(
            entityId: UUID(),
            entityType: "notebook",
            localData: local,
            remoteData: remote,
            localModifiedAt: localModifiedAt,
            remoteModifiedAt: remoteModifiedAt
        )
    }
    
    /// 解决冲突
    func resolveConflict(_ conflict: SyncConflict) -> Any? {
        switch conflictResolution {
        case .localWins:
            return conflict.localData
        case .remoteWins:
            return conflict.remoteData
        case .newestWins:
            return conflict.newest()
        case .manual:
            // 需要用户手动选择
            return nil
        }
    }
}
