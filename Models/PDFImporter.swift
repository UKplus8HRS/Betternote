import Foundation
import PDFKit
import PencilKit

/// PDF 导入管理器
/// 从 PDF 文件导入页面
final class PDFImporter {
    
    /// 导入结果
    struct ImportResult {
        var pages: [NotePage]
        var successCount: Int
        var failedCount: Int
    }
    
    /// 导入错误
    enum ImportError: LocalizedError {
        case fileNotFound
        case invalidPDF
        case noPages
        case importFailed
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound: return "文件未找到"
            case .invalidPDF: return "无效的 PDF 文件"
            case .noPages: return "PDF 没有页面"
            case .importFailed: return "导入失败"
            }
        }
    }
    
    /// 从 URL 导入 PDF
    /// - Parameters:
    ///   - url: PDF 文件 URL
    ///   - completion: 完成回调
    static func importFrom(url: URL, completion: @escaping (Result<ImportResult, ImportError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard FileManager.default.fileExists(atPath: url.path) else {
                DispatchQueue.main.async {
                    completion(.failure(.fileNotFound))
                }
                return
            }
            
            guard let pdfDocument = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidPDF))
                }
                return
            }
            
            let pageCount = pdfDocument.pageCount
            guard pageCount > 0 else {
                DispatchQueue.main.async {
                    completion(.failure(.noPages))
                }
                return
            }
            
            var pages: [NotePage] = []
            var successCount = 0
            var failedCount = 0
            
            for i in 0..<pageCount {
                guard let pdfPage = pdfDocument.page(at: i) else {
                    failedCount += 1
                    continue
                }
                
                // 将 PDF 页面转换为图像
                if let notePage = convertPDFPageToNotePage(pdfPage, pageNumber: i) {
                    pages.append(notePage)
                    successCount += 1
                } else {
                    failedCount += 1
                }
            }
            
            let result = ImportResult(
                pages: pages,
                successCount: successCount,
                failedCount: failedCount
            )
            
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
    
    /// 将 PDF 页面转换为笔记页面
    private static func convertPDFPageToNotePage(_ pdfPage: PDFPage, pageNumber: Int) -> NotePage? {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        
        // 创建高分辨率图像
        let scale: CGFloat = 2.0
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let image = renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))
            
            // 绘制 PDF 内容
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
        }
        
        // 转换为 PencilKit 绘图
        let drawing = PKDrawing(image: image)
        let drawingData = drawing.dataRepresentation()
        
        // 创建笔记页面
        var notePage = NotePage()
        notePage.updateDrawing(drawingData)
        
        // 生成缩略图
        let thumbnail = drawing.image(from: drawing.bounds, scale: 0.5)
        if let thumbnailData = thumbnail.pngData() {
            notePage.updateThumbnail(thumbnailData)
        }
        
        return notePage
    }
    
    /// 从 Data 导入 PDF
    static func importFrom(data: Data, completion: @escaping (Result<ImportResult, ImportError>) -> Void) {
        // 保存到临时文件
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("import_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try data.write(to: tempURL)
            importFrom(url: tempURL) { result in
                // 清理临时文件
                try? FileManager.default.removeItem(at: tempURL)
                completion(result)
            }
        } catch {
            completion(.failure(.importFailed))
        }
    }
}
