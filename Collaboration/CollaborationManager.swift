import Foundation

/// 协作者模型
struct Collaborator: Identifiable, Codable {
    var id: UUID
    var name: String
    var email: String
    var avatarURL: URL?
    var role: CollaboratorRole
    var joinedAt: Date
    
    enum CollaboratorRole: String, Codable {
        case owner = "所有者"
        case editor = "编辑者"
        case viewer = "查看者"
    }
    
    init(id: UUID = UUID(), name: String, email: String, role: CollaboratorRole = .viewer) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = nil
        self.role = role
        self.joinedAt = Date()
    }
}

/// 共享笔记本
struct SharedNotebook: Identifiable, Codable {
    var id: UUID
    var notebookId: UUID
    var shareLink: String?
    var collaborators: [Collaborator]
    var isPublic: Bool
    var allowCopy: Bool
    var password: String?  // 加密后的密码
    
    init(notebookId: UUID) {
        self.id = UUID()
        self.notebookId = notebookId
        self.shareLink = nil
        self.collaborators = []
        self.isPublic = false
        self.allowCopy = true
        self.password = nil
    }
    
    /// 生成分享链接
    mutating func generateShareLink(baseURL: String = "https://betternotes.app/share") {
        let token = UUID().uuidString
        shareLink = "\(baseURL)/\(token)"
    }
}

/// 协作管理器
final class CollaborationManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var sharedNotebooks: [SharedNotebook] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - 分享方法
    
    /// 分享笔记本
    func share(notebook: Notebook, with link: Bool = true, password: String? = nil) -> SharedNotebook {
        var shared = SharedNotebook(notebookId: notebook.id)
        
        if link {
            shared.generateShareLink()
        }
        
        if let password = password {
            // 简单加密 (实际应该用更安全的方式)
            shared.password = String(password.reversed())
        }
        
        sharedNotebooks.append(shared)
        
        return shared
    }
    
    /// 停止分享
    func unshare(notebookId: UUID) {
        sharedNotebooks.removeAll { $0.notebookId == notebookId }
    }
    
    /// 添加协作者
    func addCollaborator(to notebookId: UUID, collaborator: Collaborator) {
        if let index = sharedNotebooks.firstIndex(where: { $0.notebookId == notebookId }) {
            sharedNotebooks[index].collaborators.append(collaborator)
        }
    }
    
    /// 移除协作者
    func removeCollaborator(from notebookId: UUID, collaboratorId: UUID) {
        if let index = sharedNotebooks.firstIndex(where: { $0.notebookId == notebookId }) {
            sharedNotebooks[index].collaborators.removeAll { $0.id == collaboratorId }
        }
    }
    
    /// 更新协作者权限
    func updateCollaboratorRole(notebookId: UUID, collaboratorId: UUID, role: Collaborator.CollaboratorRole) {
        if let index = sharedNotebooks.firstIndex(where: { $0.notebookId == notebookId }) {
            if let collabIndex = sharedNotebooks[index].collaborators.firstIndex(where: { $0.id == collaboratorId }) {
                sharedNotebooks[index].collaborators[collabIndex].role = role
            }
        }
    }
}

// MARK: - 分享视图

import SwiftUI

struct ShareNotebookView: View {
    @ObservedObject var collaborationManager: CollaborationManager
    let notebook: Notebook
    @State private var isPublic: Bool = false
    @State private var allowCopy: Bool = true
    @State private var password: String = ""
    @State private var showingShareSheet = false
    
    var body: some View {
        List {
            Section("分享方式") {
                Toggle("公开分享", isOn: $isPublic)
                Toggle("允许复制", isOn: $allowCopy)
                
                if isPublic || password.isNotEmpty {
                    SecureField("设置密码 (可选)", text: $password)
                }
            }
            
            Section("分享链接") {
                if let shared = collaborationManager.sharedNotebooks.first(where: { $0.notebookId == notebook.id }),
                   let link = shared.shareLink {
                    HStack {
                        Text(link)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button("复制") {
                            UIPasteboard.general.string = link
                        }
                    }
                } else {
                    Button("生成分享链接") {
                        createShareLink()
                    }
                }
            }
            
            Section("协作者") {
                ForEach(getCollaborators()) { collaborator in
                    CollaboratorRow(collaborator: collaborator) { newRole in
                        collaborationManager.updateCollaboratorRole(
                            notebookId: notebook.id,
                            collaboratorId: collaborator.id,
                            role: newRole
                        )
                    }
                }
                
                Button("邀请协作者") {
                    // 打开邀请界面
                }
            }
        }
    }
    
    private func createShareLink() {
        let _ = collaborationManager.share(
            notebook: notebook,
            with: true,
            password: password.isEmpty ? nil : password
        )
    }
    
    private func getCollaborators() -> [Collaborator] {
        collaborationManager.sharedNotebooks
            .first(where: { $0.notebookId == notebook.id })?
            .collaborators ?? []
    }
}

struct CollaboratorRow: View {
    let collaborator: Collaborator
    let onRoleChange: (Collaborator.CollaboratorRole) -> Void
    
    var body: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(collaborator.name.prefix(1)))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading) {
                Text(collaborator.name)
                    .font(.headline)
                Text(collaborator.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                ForEach([Collaborator.CollaboratorRole.owner, .editor, .viewer], id: \.self) { role in
                    Button(role.rawValue) {
                        onRoleChange(role)
                    }
                }
                
                Button("移除", role: .destructive) {
                    // 移除协作者
                }
            } label: {
                Text(collaborator.role.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - String 扩展

extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
}
