import Foundation
import PDFKit

/// PDF 导出管理器
/// 将笔记导出为 PDF 文件
final class PDFExporter {
    
    /// 导出选项
    struct ExportOptions {
        var includeBackground: Bool = true
        var imageQuality: CGFloat = 1.0
        var pageSize: CGSize = CGSize(width: 612, height: 792) // Letter size
    }
    
    /// 导出结果
    enum ExportResult {
        case success(URL)
        case failure(Error)
    }
    
    /// 导出错误
    enum ExportError: LocalizedError {
        case noData
        case renderingFailed
        case saveFailed
        case invalidPage
        
        var errorDescription: String? {
            switch self {
            case .noData: return "没有可导出的数据"
            case .renderingFailed: return "渲染失败"
            case .saveFailed: return "保存文件失败"
            case .invalidPage: return "无效的页面"
            }
        }
    }
    
    /// 导出笔记本为 PDF
    /// - Parameters:
    ///   - notebook: 笔记本
    ///   - options: 导出选项
    ///   - completion: 完成回调
    static func export(notebook: Notebook, options: ExportOptions = ExportOptions(), completion: @escaping (ExportResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfDocument = PDFDocument()
            
            for (index, page) in notebook.pages.enumerated() {
                // 创建 PDF 页面
                if let pdfPage = createPDFPage(from: page, options: options) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            // 保存到临时文件
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(notebook.title)_\(Date().timeIntervalSince1970).pdf")
            
            if pdfDocument.write(to: tempURL) {
                DispatchQueue.main.async {
                    completion(.success(tempURL))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(ExportError.saveFailed))
                }
            }
        }
    }
    
    /// 从笔记页面创建 PDF 页面
    private static func createPDFPage(from notePage: NotePage, options: ExportOptions) -> PDFPage? {
        let pageRect = CGRect(origin: .zero, size: options.pageSize)
        
        // 创建渲染器
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // 绘制背景
            if options.includeBackground {
                let backgroundColor = UIColor(hex: notePage.backgroundColor) ?? .white
                backgroundColor.setFill()
                context.fill(pageRect)
            }
            
            // 绘制模板网格
            drawTemplate(notePage.templateType, in: pageRect, context: context.cgContext)
            
            // 绘制笔记内容
            if let drawingData = notePage.drawingData,
               let drawing = try? PKDrawing(data: drawingData) {
                let image = drawing.image(from: drawing.bounds, scale: options.imageQuality)
                image.draw(in: pageRect)
            }
        }
        
        return PDFPage(data: data)
    }
    
    /// 绘制模板网格
    private static func drawTemplate(_ template: PageTemplate, in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        let lineColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        context.setStrokeColor(lineColor)
        context.setLineWidth(0.5)
        
        switch template {
        case .blank:
            break
            
        case .lined:
            let spacing: CGFloat = 30
            var y = spacing
            while y < rect.height {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: rect.width, y: y))
                y += spacing
            }
            context.strokePath()
            
        case .grid:
            let spacing: CGFloat = 30
            var x = spacing
            while x < rect.width {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: rect.height))
                x += spacing
            }
            var y = spacing
            while y < rect.height {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: rect.width, y: y))
                y += spacing
            }
            context.strokePath()
            
        case .dotted:
            let spacing: CGFloat = 20
            context.setFillColor(lineColor)
            var x = spacing
            while x < rect.width {
                var y = spacing
                while y < rect.height {
                    let dotRect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    context.fillEllipse(in: dotRect)
                    y += spacing
                }
                x += spacing
            }
            
        case .checklist:
            let spacing: CGFloat = 40
            var y = spacing
            while y < rect.height {
                // 复选框
                context.setStrokeColor(lineColor)
                context.stroke(CGRect(x: 40, y: y - 12, width: 16, height: 16))
                // 横线
                context.move(to: CGPoint(x: 70, y: y))
                context.addLine(to: CGPoint(x: rect.width - 40, y: y))
                context.strokePath()
                y += spacing
            }
            
        case .calendar:
            // 绘制日历网格
            let headerHeight: CGFloat = 50
            let dayHeight = (rect.height - headerHeight) / 6
            
            // 头部
            context.setStrokeColor(lineColor)
            context.stroke(CGRect(x: 0, y: headerHeight, width: rect.width, height: dayHeight))
            
            // 垂直线
            let colWidth = rect.width / 7
            for i in 1..<7 {
                let x = CGFloat(i) * colWidth
                context.move(to: CGPoint(x: x, y: headerHeight))
                context.addLine(to: CGPoint(x: x, y: rect.height))
            }
            // 水平线
            for i in 1..<6 {
                let y = headerHeight + CGFloat(i) * dayHeight
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: rect.width, y: y))
            }
            context.strokePath()
        }
        
        context.restoreGState()
    }
}

// MARK: - UIColor 扩展

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
