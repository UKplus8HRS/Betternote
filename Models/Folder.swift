import Foundation

/// 文件夹模型
/// 用于组织笔记本
struct Folder: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String
    var notebookIds: [UUID]
    var createdAt: Date
    var modifiedAt: Date
    var isExpanded: Bool  // 在列表中是否展开
    
    /// 默认构造函数
    init(id: UUID = UUID(), name: String = "新文件夹", color: String = "blue") {
        self.id = id
        self.name = name
        self.color = color
        self.notebookIds = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isExpanded = true
    }
    
    /// 添加笔记本到文件夹
    mutating func addNotebook(_ notebookId: UUID) {
        if !notebookIds.contains(notebookId) {
            notebookIds.append(notebookId)
            modifiedAt = Date()
        }
    }
    
    /// 从文件夹移除笔记本
    mutating func removeNotebook(_ notebookId: UUID) {
        notebookIds.removeAll { $0 == notebookId }
        modifiedAt = Date()
    }
}

/// 文件夹颜色选项
enum FolderColor: String, CaseIterable {
    case blue = "blue"
    case red = "red"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case yellow = "yellow"
    case gray = "gray"
    
    var iconName: String {
        switch self {
        case .blue: return "folder.fill"
        case .red: return "folder.fill"
        case .green: return "folder.fill"
        case .orange: return "folder.fill"
        case .purple: return "folder.fill"
        case .yellow: return "folder.fill"
        case .gray: return "folder"
        }
    }
}
