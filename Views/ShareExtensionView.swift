import SwiftUI
import UniformTypeIdentifiers

/// 分享扩展视图
/// 从其他应用分享内容到笔记
struct ShareExtensionView: View {
    @Environment(\.dismiss) var dismiss
    
    let sharedItems: [SharedItem]
    @State private var selectedNotebook: Notebook?
    @State private var isImporting: Bool = false
    
    struct SharedItem: Identifiable {
        let id = UUID()
        let type: SharedItemType
        let data: Any
        let preview: String?
        
        enum SharedItemType {
            case image(Data)
            case pdf(URL)
            case text(String)
            case url(URL)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 预览分享内容
                previewSection
                
                // 选择目标笔记本
                notebookSelector
                
                Spacer()
                
                // 确认按钮
                Button(action: importToNotebook) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入到笔记")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedNotebook != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedNotebook == nil)
            }
            .padding()
            .navigationTitle("分享到笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 预览区域
    
    private var previewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("分享内容")
                    .font(.headline)
                Spacer()
                Text("\(sharedItems.count) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sharedItems) { item in
                        SharedItemPreview(item: item)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 笔记本选择
    
    private var notebookSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择笔记本")
                .font(.headline)
            
            if let notebook = selectedNotebook {
                HStack {
                    Circle()
                        .fill(Color(hex: notebook.coverColor) ?? .blue)
                        .frame(width: 20, height: 20)
                    
                    Text(notebook.title)
                        .font(.body)
                    
                    Spacer()
                    
                    Button("更改") {
                        selectedNotebook = nil
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            } else {
                // 笔记本列表 (简化版)
                VStack(spacing: 8) {
                    Text("从笔记应用选择")
                        .foregroundColor(.secondary)
                    
                    // 这里应该显示笔记本选择器
                    Button("选择笔记本") {
                        // 打开笔记本选择器
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
    
    // MARK: - 方法
    
    private func importToNotebook() {
        // 实现导入逻辑
        dismiss()
    }
}

// MARK: - 分享项目预览

struct SharedItemPreview: View {
    let item: ShareExtensionView.SharedItem
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(item.preview ?? typeName)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80, height: 80)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch item.type {
        case .image: return "photo"
        case .pdf: return "doc.fill"
        case .text: return "doc.text"
        case .url: return "link"
        }
    }
    
    private var typeName: String {
        switch item.type {
        case .image: return "图片"
        case .pdf: return "PDF"
        case .text: return "文本"
        case .url: return "链接"
        }
    }
}

// MARK: - App Clip 入口

/// App Clip 入口视图
/// 用于从主屏幕小组件快速进入
struct AppClipEntryView: View {
    let notebooks: [Notebook]
    let onSelectNotebook: (Notebook) -> Void
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("快速笔记")
                    .font(.headline)
            }
            
            // 最近笔记
            if !notebooks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(notebooks.prefix(3)) { notebook in
                        Button(action: { onSelectNotebook(notebook) }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: notebook.coverColor) ?? .blue)
                                    .frame(width: 12, height: 12)
                                Text(notebook.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // 新建笔记
            Button(action: onCreateNew) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新建笔记")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
