import Foundation

/// 导入管理器
/// 支持从各种格式导入内容
final class ImportManager: ObservableObject {
    
    // MARK: - 支持的格式
    
    enum ImportFormat {
        case image
        case webPage
        case text
        case markdown
        case goodnotes
        case notability
        case onenote
        
        var icon: String {
            switch self {
            case .image: return "photo"
            case .webPage: return "globe"
            case .text: return "doc.text"
            case .markdown: return "text.alignleft"
            case .goodnotes: return "doc.richtext"
            case .notability: return "doc.text"
            case .onenote: return "book"
            }
        }
        
        var fileExtensions: [String] {
            switch self {
            case .image: return ["jpg", "jpeg", "png", "gif", "heic"]
            case .webPage: return ["html", "htm"]
            case .text: return ["txt"]
            case .markdown: return ["md", "markdown"]
            case .goodnotes: return ["goodnotes"]
            case .notability: return ["notability"]
            case .onenote: return ["one"]
            }
        }
    }
    
    // MARK: - Published 属性
    
    @Published var isImporting: Bool = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    // MARK: - 导入方法
    
    /// 从图片导入
    func importFromImage(_ imageURL: URL) async -> NotePage? {
        await MainActor.run {
            isImporting = true
            progress = 0
        }
        
        defer {
            Task { @MainActor in
                isImporting = false
            }
        }
        
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            await MainActor.run { error = "无法读取图片" }
            return nil
        }
        
        await MainActor.run { progress = 0.5 }
        
        // 转换为 PencilKit 绘图
        let drawing = PKDrawing(image: image)
        var page = NotePage()
        page.updateDrawing(drawing.dataRepresentation())
        
        // 生成缩略图
        let thumbnail = drawing.image(from: drawing.bounds, scale: 0.5)
        if let data = thumbnail.pngData() {
            page.updateThumbnail(data)
        }
        
        await MainActor.run { progress = 1.0 }
        
        return page
    }
    
    /// 从文本导入
    func importFromText(_ text: String) async -> NotePage {
        var page = NotePage(template: .lined)
        
        // 文本将作为图片嵌入
        // 实际实现需要渲染文本到图像
        
        return page
    }
    
    /// 从网页导入
    func importFromWebPage(_ html: String) async -> NotePage? {
        // 提取图片或文本
        return nil
    }
    
    /// 从 GoodNotes 导入 (需要解析特定格式)
    func importFromGoodNotes(_ url: URL) async -> [NotePage]? {
        // GoodNotes 使用特定格式，需要解析
        // 这里简化实现
        return nil
    }
    
    /// 从 Notability 导入
    func importFromNotability(_ url: URL) async -> [NotePage]? {
        // Notability 使用 gnotability 格式
        return nil
    }
}

// MARK: - 导入视图

import SwiftUI

struct ImportView: View {
    @ObservedObject var importManager: ImportManager
    @Environment(\.dismiss) var dismiss
    
    let onImport: ([NotePage]) -> Void
    
    var body: some View {
        List {
            Section("导入方式") {
                ForEach([ImportFormat.image, .text, .webPage, .markdown], id: \.self) { format in
                    Button(action: { importFrom(format) }) {
                        Label(format.icon.replacingOccurrences(of: "doc.richtext", with: "doc.richtext"), systemImage: format.icon)
                        {
                            Text(formatName(format))
                        }
                    }
                }
            }
            
            if importManager.isImporting {
                Section("导入进度") {
                    VStack {
                        ProgressView(value: importManager.progress)
                        Text("\(Int(importManager.progress * 100))%")
                            .font(.caption)
                    }
                }
            }
            
            if let error = importManager.error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func formatName(_ format: ImportFormat) -> String {
        switch format {
        case .image: return "图片"
        case .webPage: return "网页"
        case .text: return "文本"
        case .markdown: return "Markdown"
        case .goodnotes: return "GoodNotes"
        case .notability: return "Notability"
        case .onenote: return "OneNote"
        }
    }
    
    private func importFrom(_ format: ImportFormat) {
        // 使用文档选择器
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: format.fileExtensions.compactMap { UTType(filenameExtension: $0) })
        picker.delegate = // 需要实现 UIDocumentPickerDelegate
        // present(picker)
    }
}

// MARK: - UTType 扩展

import UniformTypeIdentifiers

extension ImportFormat {
    var fileExtensions: [UTType] {
        switch self {
        case .image:
            return [.jpeg, .png, .gif, .heic]
        case .webPage:
            return [.html]
        case .text:
            return [.plainText]
        case .markdown:
            return [.init(filenameExtension: "md") ?? .plainText]
        default:
            return [.data]
        }
    }
}
