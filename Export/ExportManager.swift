import Foundation

/// 导出格式
enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case image = "图片"
    case markdown = "Markdown"
    case plainText = "纯文本"
    case notebookFile = "Notebook文件"
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .image: return "photo"
        case .markdown: return "text.alignleft"
        case .plainText: return "doc.plaintext"
        case .notebookFile: return "doc.badge.gearshape"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .image: return "png"
        case .markdown: return "md"
        case .plainText: return "txt"
        case .notebookFile: return "clawnotes"
        }
    }
}

/// 导出管理器
final class ExportManager: ObservableObject {
    
    // MARK: - 导出选项
    
    struct ExportSettings {
        var format: ExportFormat = .pdf
        var includeBackground: Bool = true
        var imageQuality: CGFloat = 1.0
        var pageSize: CGSize = CGSize(width: 612, height: 792)
        var includeMetadata: Bool = true
    }
    
    // MARK: - Published 属性
    
    @Published var isExporting: Bool = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    // MARK: - 导出方法
    
    /// 导出笔记本
    func export(notebook: Notebook, settings: ExportSettings) async -> URL? {
        await MainActor.run {
            isExporting = true
            progress = 0
            error = nil
        }
        
        let totalPages = notebook.pages.count
        var exportedURLs: [URL] = []
        
        do {
            switch settings.format {
            case .pdf:
                let url = try await exportToPDF(notebook: notebook, settings: settings)
                exportedURLs.append(url)
                
            case .image:
                for (index, page) in notebook.pages.enumerated() {
                    let url = try await exportPageToImage(page: page, index: index, settings: settings)
                    exportedURLs.append(url)
                    
                    await MainActor.run {
                        progress = Double(index + 1) / Double(totalPages)
                    }
                }
                
            case .markdown:
                let url = exportToMarkdown(notebook: notebook)
                exportedURLs.append(url)
                
            case .plainText:
                let url = exportToPlainText(notebook: notebook)
                exportedURLs.append(url)
                
            case .notebookFile:
                let url = exportToNotebookFile(notebook: notebook)
                exportedURLs.append(url)
            }
            
            await MainActor.run {
                isExporting = false
                progress = 1.0
            }
            
            // 如果是多文件，打包成 ZIP
            if exportedURLs.count > 1 {
                return try await zipFiles(exportedURLs, named: notebook.title)
            }
            
            return exportedURLs.first
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isExporting = false
            }
            return nil
        }
    }
    
    // MARK: - 私有方法
    
    private func exportToPDF(notebook: Notebook, settings: ExportSettings) async throws -> URL {
        return await withCheckedContinuation { continuation in
            PDFExporter.export(notebook: notebook, options: PDFExporter.ExportOptions()) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func exportPageToImage(page: NotePage, index: Int, settings: ExportSettings) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "page_\(index + 1).png"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        if let drawingData = page.drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            let image = drawing.image(from: drawing.bounds, scale: settings.imageQuality)
            
            if let data = image.pngData() {
                try data.write(to: fileURL)
            }
        }
        
        return fileURL
    }
    
    private func exportToMarkdown(notebook: Notebook) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(notebook.title).md")
        
        var content = "# \(notebook.title)\n\n"
        content += "*创建于 \(formatDate(notebook.createdAt))*\n\n"
        content += "---\n\n"
        
        for (index, page) in notebook.pages.enumerated() {
            content += "## 第 \(index + 1) 页\n\n"
            
            // 可以在这里添加手写识别的文本
            content += "---\n\n"
        }
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func exportToPlainText(notebook: Notebook) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(notebook.title).txt")
        
        var content = "\(notebook.title)\n"
        content += String(repeating: "=", count: notebook.title.count) + "\n\n"
        
        for (index, _) in notebook.pages.enumerated() {
            content += "--- 第 \(index + 1) 页 ---\n\n"
        }
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func exportToNotebookFile(notebook: Notebook) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(notebook.title).clawnotes")
        
        do {
            let data = try JSONEncoder().encode(notebook)
            try data.write(to: fileURL)
        } catch {
            print("导出失败: \(error)")
        }
        
        return fileURL
    }
    
    private func zipFiles(_ urls: [URL], named name: String) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent("\(name).zip")
        
        // 简化实现 - 实际应该用 ZIPFoundation 或类似库
        // 这里只是返回第一个文件
        return urls.first ?? urls[0]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
