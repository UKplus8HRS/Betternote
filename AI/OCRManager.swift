import Foundation
import Vision
import UIKit

/// OCR 文字提取管理器
/// 从图片/PDF 中提取文字
final class OCRManager: ObservableObject {
    
    // MARK: - OCR 结果
    
    struct OCRResult {
        var text: String
        var boundingBoxes: [CGRect]
        var confidence: Float
        var language: String
    }
    
    // MARK: - Published 属性
    
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var result: OCRResult?
    @Published var error: String?
    
    // MARK: - 支持的语言
    
    static let supportedLanguages = [
        "en-US": "英语",
        "zh-Hans": "简体中文",
        "zh-Hant": "繁体中文",
        "ja": "日语",
        "ko": "韩语"
    ]
    
    // MARK: - OCR 方法
    
    /// 从图片提取文字
    func recognizeText(from image: UIImage, language: String = "zh-Hans") async -> OCRResult? {
        await MainActor.run {
            isProcessing = true
            progress = 0
            error = nil
        }
        
        guard let cgImage = image.cgImage else {
            await MainActor.run { error = "无法读取图片" }
            return nil
        }
        
        return await recognizeText(from: cgImage, language: language)
    }
    
    /// 从 CGImage 提取文字
    private func recognizeText(from cgImage: CGImage, language: String) async -> OCRResult? {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var text = ""
                var boxes: [CGRect] = []
                var totalConfidence: Float = 0
                
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        text += topCandidate.string + "\n"
                        boxes.append(observation.boundingBox)
                        totalConfidence += topCandidate.confidence
                    }
                }
                
                let result = OCRResult(
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    boundingBoxes: boxes,
                    confidence: totalConfidence / Float(max(observations.count, 1)),
                    language: language
                )
                
                continuation.resume(returning: result)
            }
            
            // 配置请求
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = [language]
            
            // 执行请求
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// 从 PDF 提取文字
    func recognizeText(from pdfURL: URL, pageIndex: Int = 0, language: String = "zh-Hans") async -> OCRResult? {
        await MainActor.run { progress = 0.3 }
        
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            await MainActor.run { error = "无法读取 PDF" }
            return nil
        }
        
        // 将 PDF 页面渲染为图像
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        await MainActor.run { progress = 0.6 }
        
        return await recognizeText(from: image, language: language)
    }
    
    /// 从图片数组提取 (多页 PDF)
    func recognizeText(from images: [UIImage], language: String = "zh-Hans") async -> [OCRResult] {
        var results: [OCRResult] = []
        
        for (index, image) in images.enumerated() {
            await MainActor.run { progress = Double(index) / Double(images.count) }
            
            if let result = await recognizeText(from: image, language: language) {
                results.append(result)
            }
        }
        
        await MainActor.run { progress = 1.0 }
        
        return results
    }
}

// MARK: - PDFKit 导入

import PDFKit
