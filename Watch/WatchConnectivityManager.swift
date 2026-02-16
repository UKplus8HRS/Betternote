import SwiftUI
import WatchConnectivity

/// Apple Watch 连接管理器
/// 实现 iPad 与 Apple Watch 的同步
final class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var isWatchConnected: Bool = false
    @Published var isPaired: Bool = false
    @Published var receivedMessage: [String: Any]?
    
    // MARK: - 初始化
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - 设置
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - 发送消息
    
    /// 发送笔记列表到 Watch
    func sendNotebooks(_ notebooks: [Notebook]) {
        guard WCSession.default.activationState == .activated else { return }
        
        let notebooksData = notebooks.map { notebook -> [String: Any] in
            return [
                "id": notebook.id.uuidString,
                "title": notebook.title,
                "pageCount": notebook.pages.count
            ]
        }
        
        let message: [String: Any] = [
            "type": "notebooks",
            "data": notebooksData
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil)
    }
    
    /// 发送最近笔记到 Watch
    func sendRecentNotes(_ notebooks: [Notebook]) {
        guard WCSession.default.activationState == .activated else { return }
        
        // 只发送最新的 3 个笔记本
        let recent = Array(notebooks.prefix(3))
        
        sendNotebooks(recent)
    }
    
    /// 发送快速笔记请求
    func requestQuickNote() {
        guard WCSession.default.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "type": "quickNote",
            "action": "create"
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            self.isPaired = session.isPaired
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
        
        // 重新激活
        WCSession.default.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = message
            
            // 处理来自 Watch 的消息
            if let type = message["type"] as? String {
                switch type {
                case "openNotebook":
                    if let idString = message["notebookId"] as? String {
                        // 通知主应用打开笔记本
                        NotificationCenter.default.post(
                            name: .openNotebook,
                            object: nil,
                            userInfo: ["notebookId": idString]
                        )
                    }
                case "newPage":
                    // 创建新页面
                    NotificationCenter.default.post(name: .createNewPage, object: nil)
                default:
                    break
                }
            }
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let openNotebook = Notification.Name("openNotebook")
    static let createNewPage = Notification.Name("createNewPage")
}
