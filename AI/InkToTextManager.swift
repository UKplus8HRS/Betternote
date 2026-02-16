import Foundation
import Vision
import PencilKit

/// 墨迹转文字管理器
/// 将手写文字转换为可编辑文本
final class InkToTextManager: ObservableObject {
    
    // MARK: - 转换结果
    
    struct ConversionResult {
        var text: String
        var boundingBoxes: [CGRect]
        var words: [WordInfo]
        
        struct WordInfo {
            var text: String
            var boundingBox: CGRect
            var confidence: Float
        }
    }
    
    // MARK: - Published 属性
    
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var result: ConversionResult?
    @Published var error: String?
    
    // MARK: - 转换方法
    
    /// 将绘图转换为文字
    func convertToText(_ drawing: PKDrawing) async -> ConversionResult? {
        await MainActor.run {
            isProcessing = true
            progress = 0
            error = nil
        }
        
        // 将 PKDrawing 转换为图像
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        
        guard let cgImage = image.cgImage else {
            await MainActor.run { error = "无法转换绘图" }
            return nil
        }
        
        await MainActor.run { progress = 0.3 }
        
        // 使用 Vision 框架识别
        return await recognizeText(from: cgImage)
    }
    
    /// 识别图像中的文字
    private func recognizeText(from cgImage: CGImage) async -> ConversionResult? {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var allText = ""
                var allBoxes: [CGRect] = []
                var words: [ConversionResult.WordInfo] = []
                
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        allText += topCandidate.string + " "
                        allBoxes.append(observation.boundingBox)
                        
                        // 分割单词
                        let wordInfo = ConversionResult.WordInfo(
                            text: topCandidate.string,
                            boundingBox: observation.boundingBox,
                            confidence: topCandidate.confidence
                        )
                        words.append(wordInfo)
                    }
                }
                
                let result = ConversionResult(
                    text: allText.trimmingCharacters(in: .whitespacesAndNewlines),
                    boundingBoxes: allBoxes,
                    words: words
                )
                
                continuation.resume(returning: result)
            }
            
            // 配置请求 - 使用手写识别
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false  // 手写不需要语言纠正
            
            // 设置识别语言
            request.recognitionLanguages = ["en-US", "zh-Hans"]
            
            // 自定义单词 - 提高识别率
            request.customWords = ["the", "and", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "shall", "can", "need", "dare", "ought", "used", "to", "of", "in", "for", "on", "with", "at", "by", "from", "as", "into", "through", "during", "before", "after", "above", "below", "between", "under", "again", "further", "then", "once"]
            
            // 执行请求
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// 转换指定区域
    func convertRegion(_ drawing: PKDrawing, in rect: CGRect) async -> ConversionResult? {
        // 裁剪绘图
        let croppedDrawing = drawing.image(from: rect, scale: 2.0)
        
        guard let cgImage = croppedDrawing.cgImage else {
            return nil
        }
        
        return await recognizeText(from: cgImage)
    }
    
    /// 批量转换多页
    func convertPages(_ drawings: [PKDrawing]) async -> [ConversionResult] {
        var results: [ConversionResult] = []
        
        for (index, drawing) in drawings.enumerated() {
            await MainActor.run { progress = Double(index) / Double(drawings.count) }
            
            if let result = await convertToText(drawing) {
                results.append(result)
            }
        }
        
        await MainActor.run { progress = 1.0 }
        
        return results
    }
}
