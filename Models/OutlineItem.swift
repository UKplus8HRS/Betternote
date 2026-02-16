import Foundation

/// 大纲项目模型
/// 用于大纲模式中的目录/标题
struct OutlineItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var pageIndex: Int        // 对应页面索引
    var parentId: UUID?       // 父项目 ID (用于嵌套)
    var isExpanded: Bool     // 是否展开
    var children: [OutlineItem]  // 子项目
    var level: Int          // 缩进级别
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        pageIndex: Int,
        parentId: UUID? = nil,
        level: Int = 0
    ) {
        self.id = id
        self.title = title
        self.pageIndex = pageIndex
        self.parentId = parentId
        self.isExpanded = true
        self.children = []
        self.level = level
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// 从页面创建大纲项目
    static func fromPage(title: String, pageIndex: Int) -> OutlineItem {
        return OutlineItem(title: title, pageIndex: pageIndex)
    }
}

/// 笔记本大纲
struct NotebookOutline: Identifiable, Codable {
    var id: UUID
    var notebookId: UUID
    var items: [OutlineItem]
    var lastModified: Date
    
    init(notebookId: UUID) {
        self.id = UUID()
        self.notebookId = notebookId
        self.items = []
        self.lastModified = Date()
    }
    
    /// 从笔记本生成大纲
    static func generate(from notebook: Notebook) -> NotebookOutline {
        var outline = NotebookOutline(notebookId: notebook.id)
        
        // 每个页面作为一个大纲项目
        for (index, _) in notebook.pages.enumerated() {
            let item = OutlineItem(
                title: "第 \(index + 1) 页",
                pageIndex: index,
                level: 0
            )
            outline.items.append(item)
        }
        
        outline.lastModified = Date()
        return outline
    }
    
    /// 添加大纲项目
    mutating func addItem(_ item: OutlineItem) {
        items.append(item)
        lastModified = Date()
    }
    
    /// 删除大纲项目
    mutating func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        // 也删除子项目
        items.removeAll { $0.parentId == id }
        lastModified = Date()
    }
    
    /// 更新大纲项目
    mutating func updateItem(_ item: OutlineItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            lastModified = Date()
        }
    }
    
    /// 移动大纲项目
    mutating func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        lastModified = Date()
    }
    
    /// 获取扁平化的项目列表 (包括嵌套的)
    func flattenedItems() -> [OutlineItem] {
        var result: [OutlineItem] = []
        
        for item in items {
            result.append(item)
            if item.isExpanded {
                result.append(contentsOf: flattenChildren(item.children))
            }
        }
        
        return result
    }
    
    private func flattenChildren(_ children: [OutlineItem]) -> [OutlineItem] {
        var result: [OutlineItem] = []
        for child in children {
            result.append(child)
            if child.isExpanded {
                result.append(contentsOf: flattenChildren(child.children))
            }
        }
        return result
    }
}
