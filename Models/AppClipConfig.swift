import Foundation

/// 应用嵌入配置
/// 用于跨应用嵌入笔记
struct AppClipConfig {
    var enabled: Bool = true
    var defaultNotebookId: UUID?
    var maxNotes: Int = 5  // App Clip 中最多显示的笔记数
}

/// 小组件配置
/// 用于主屏幕小组件
struct WidgetConfig {
    var kind: String
    var displayName: String
    var description: String
    var supportedFamilies: [String]  // ["small", "medium", "large"]
    
    // 预设小组件
    static let recentNotes = WidgetConfig(
        kind: "RecentNotes",
        displayName: "最近笔记",
        description: "快速访问最近使用的笔记",
        supportedFamilies: ["systemSmall", "systemMedium"]
    )
    
    static let quickNote = WidgetConfig(
        kind: "QuickNote",
        displayName: "快速笔记",
        description: "一键创建新笔记",
        supportedFamilies: ["systemSmall"]
    )
    
    static let folderWidget = WidgetConfig(
        kind: "FolderView",
        displayName: "文件夹",
        description: "查看文件夹中的笔记",
        supportedFamilies: ["systemSmall", "systemMedium"]
    )
    
    static let all: [WidgetConfig] = [recentNotes, quickNote, folderWidget]
}

/// 分享扩展配置
/// 用于从其他应用分享内容到笔记
struct ShareExtensionConfig {
    var enabled: Bool = true
    var supportedTypes: [String]  // ["image", "pdf", "text", "url"]
    
    static let `default` = ShareExtensionConfig(
        enabled: true,
        supportedTypes: ["image", "pdf", "text", "url"]
    )
}
