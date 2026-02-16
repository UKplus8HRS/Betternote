import SwiftUI
import WidgetKit

/// iOS Widget 支持
/// 提供桌面小组件快速访问
final class WidgetManager {
    
    /// 组件Kind标识
    static let recentNotesKind = "RecentNotesWidget"
    static let quickNoteKind = "QuickNoteWidget"
    static let folderWidgetKind = "FolderWidget"
    
    /// 刷新所有小组件
    static func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 刷新特定组件
    static func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

// MARK: - 小组件数据模型

struct NoteWidgetEntry: TimelineEntry {
    let date: Date
    let notebooks: [Notebook]
    let recentPages: [PageThumbnail]
}

struct PageThumbnail: Identifiable {
    let id = UUID()
    let notebookTitle: String
    let pageNumber: Int
    let thumbnailData: Data?
}

// MARK: - 快速笔记组件

struct QuickNoteEntry: TimelineEntry {
    let date: Date
    let lastOpenedNotebook: Notebook?
    let pageCount: Int
}

// MARK: - Widget Bundle

@main
struct NoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecentNotesWidget()
        QuickNoteWidget()
    }
}

// MARK: - 最近笔记组件

struct RecentNotesWidget: Widget {
    let kind: String = WidgetManager.recentNotesKind
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentNotesProvider()) { entry in
            RecentNotesWidgetView(entry: entry)
        }
        .configurationDisplayName("最近笔记")
        .description("快速访问最近使用的笔记")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> NoteWidgetEntry {
        NoteWidgetEntry(date: Date(), notebooks: [], recentPages: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NoteWidgetEntry) -> Void) {
        let entry = NoteWidgetEntry(date: Date(), notebooks: [], recentPages: [])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteWidgetEntry>) -> Void) {
        // 从本地存储加载数据
        let localStorage = LocalStorageManager()
        let notebooks = localStorage.loadNotebooks()
        
        let entry = NoteWidgetEntry(date: Date(), notebooks: notebooks, recentPages: [])
        
        // 每小时更新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct RecentNotesWidgetView: View {
    let entry: NoteWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text("最近笔记")
                    .font(.headline)
            }
            
            if entry.notebooks.isEmpty {
                Text("暂无笔记")
                    .foregroundColor(.secondary)
            } else {
                ForEach(entry.notebooks.prefix(3)) { notebook in
                    HStack {
                        Circle()
                            .fill(Color(coverColorMap[notebook.coverColor] ?? .blue))
                            .frame(width: 8, height: 8)
                        Text(notebook.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 快速笔记组件

struct QuickNoteWidget: Widget {
    let kind: String = WidgetManager.quickNoteKind
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickNoteProvider()) { entry in
            QuickNoteWidgetView(entry: entry)
        }
        .configurationDisplayName("快速笔记")
        .description("一键创建新笔记")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(date: Date(), lastOpenedNotebook: nil, pageCount: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> Void) {
        let localStorage = LocalStorageManager()
        let notebooks = localStorage.loadNotebooks()
        let pageCount = notebooks.reduce(0) { $0 + $1.pages.count }
        
        let entry = QuickNoteEntry(
            date: Date(),
            lastOpenedNotebook: notebooks.first,
            pageCount: pageCount
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> Void) {
        let localStorage = LocalStorageManager()
        let notebooks = localStorage.loadNotebooks()
        let pageCount = notebooks.reduce(0) { $0 + $1.pages.count }
        
        let entry = QuickNoteEntry(
            date: Date(),
            lastOpenedNotebook: notebooks.first,
            pageCount: pageCount
        )
        
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickNoteWidgetView: View {
    let entry: QuickNoteEntry
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("新建笔记")
                .font(.headline)
            
            if let notebook = entry.lastOpenedNotebook {
                Text(notebook.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text("\(entry.pageCount) 页")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
