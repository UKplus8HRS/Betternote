import Foundation
import Vision
import PencilKit
import UIKit

/// 手写识别管理器
/// 使用 Vision 框架进行手写文字识别
final class HandwritingRecognitionManager {
    
    // MARK: - 识别结果
    
    struct RecognitionResult {
        var text: String
        var confidence: Float
        var boundingBox: CGRect
    }
    
    // MARK: - 识别方法
    
    /// 识别绘图中的文字
    /// - Parameters:
    ///   - drawing: PencilKit 绘图
    ///   - completion: 完成回调
    func recognizeText(from drawing: PKDrawing, completion: @escaping ([RecognitionResult]) -> Void) {
        // 将绘图转换为图像
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        // 创建文字识别请求
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            
            let results = observations.compactMap { observation -> RecognitionResult? in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }
                
                // 转换坐标
                let boundingBox = self.convertBoundingBox(observation.boundingBox, in: drawing.bounds)
                
                return RecognitionResult(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    boundingBox: boundingBox
                )
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
        
        // 配置请求
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        
        // 执行请求
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("文字识别失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// 转换坐标系统
    private func convertBoundingBox(_ box: CGRect, in bounds: CGRect) -> CGRect {
        // Vision 的坐标是归一化的 (0-1)，左下角为原点
        // 转换为 UIKit 坐标
        let x = box.origin.x * bounds.width
        let y = (1 - box.origin.y - box.height) * bounds.height
        let width = box.width * bounds.width
        let height = box.height * bounds.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - 图形识别管理器

/// 图形识别管理器
/// 自动识别绘制的形状并转换为标准图形
final class ShapeDetectionManager {
    
    /// 识别到的形状
    enum DetectedShape {
        case rectangle(rect: CGRect)
        case circle(center: CGPoint, radius: CGFloat)
        case line(start: CGPoint, end: CGPoint)
        case arrow(start: CGPoint, end: CGPoint)
        case unknown
    }
    
    /// 从绘图中检测形状
    /// - Parameter drawing: PencilKit 绘图
    /// - Returns: 检测到的形状数组
    func detectShapes(from drawing: PKDrawing) -> [DetectedShape] {
        var shapes: [DetectedShape] = []
        
        // 获取所有笔画
        let strokes = drawing.strokes
        
        for stroke in strokes {
            let path = stroke.path
            let points = path.map { $0.location }
            
            guard points.count >= 2 else { continue }
            
            // 分析点集判断形状
            if let shape = analyzePoints(points) {
                shapes.append(shape)
            }
        }
        
        return shapes
    }
    
    /// 分析点集判断形状
    private func analyzePoints(_ points: [CGPoint]) -> DetectedShape? {
        guard points.count >= 2 else { return nil }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        // 计算起点和终点的距离
        let distance = hypot(lastPoint.x - firstPoint.x, lastPoint.y - firstPoint.y)
        
        // 计算所有点到起点-终点连线的最大距离
        var maxDeviation: CGFloat = 0
        for point in points {
            let deviation = distanceFromLine(point: point, lineStart: firstPoint, lineEnd: lastPoint)
            maxDeviation = max(maxDeviation, deviation)
        }
        
        // 根据偏差判断形状
        let length = hypot(lastPoint.x - firstPoint.x, lastPoint.y - firstPoint.y)
        
        // 直线
        if maxDeviation < length * 0.1 {
            // 检查是否是箭头
            if isArrow(points: points) {
                return .arrow(start: firstPoint, end: lastPoint)
            }
            return .line(start: firstPoint, end: lastPoint)
        }
        
        // 计算包围盒
        let minX = points.map { $0.x }.min()!
        let maxX = points.map { $0.x }.max()!
        let minY = points.map { $0.y }.min()!
        let maxY = points.map { $0.y }.max()!
        
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        let aspectRatio = bounds.width / bounds.height
        
        // 矩形
        if maxDeviation < length * 0.2 && (aspectRatio > 0.8 && aspectRatio < 1.2) {
            // 检查是否是圆形
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let avgRadius = (bounds.width + bounds.height) / 4
            
            var isCircle = true
            for point in points {
                let dist = hypot(point.x - center.x, point.y - center.y)
                if abs(dist - avgRadius) > avgRadius * 0.3 {
                    isCircle = false
                    break
                }
            }
            
            if isCircle {
                return .circle(center: center, radius: avgRadius)
            }
            
            return .rectangle(rect: bounds)
        }
        
        return .unknown
    }
    
    /// 计算点到直线的距离
    private func distanceFromLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let length = sqrt(dx * dx + dy * dy)
        
        if length == 0 { return hypot(point.x - lineStart.x, point.y - lineStart.y) }
        
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (length * length)))
        
        let projX = lineStart.x + t * dx
        let projY = lineStart.y + t * dy
        
        return hypot(point.x - projX, point.y - projY)
    }
    
    /// 检查是否是箭头
    private func isArrow(points: [CGPoint]) -> Bool {
        guard points.count >= 3 else { return false }
        
        let lastThree = points.suffix(3)
        let angles = calculateAngles(points: Array(lastThree))
        
        // 如果最后几点的角度变化较大，可能是箭头
        return angles.contains { $0 > .pi / 4 }
    }
    
    /// 计算角度
    private func calculateAngles(points: [CGPoint]) -> [CGFloat] {
        guard points.count >= 3 else { return [] }
        
        var angles: [CGFloat] = []
        
        for i in 1..<(points.count - 1) {
            let v1 = CGPoint(x: points[i-1].x - points[i].x, y: points[i-1].y - points[i].y)
            let v2 = CGPoint(x: points[i+1].x - points[i].x, y: points[i+1].y - points[i].y)
            
            let dot = v1.x * v2.x + v1.y * v2.y
            let cross = v1.x * v2.y - v1.y * v2.x
            
            angles.append(atan2(cross, dot))
        }
        
        return angles
    }
}

// MARK: - 数学公式识别

/// 数学公式识别管理器
/// 识别手写数学公式并转换为 LaTeX
final class MathRecognitionManager {
    
    /// 识别结果
    struct MathResult {
        var latex: String
        var confidence: Float
    }
    
    /// 识别数学公式
    /// - Parameters:
    ///   - drawing: PencilKit 绘图
    ///   - completion: 完成回调
    func recognizeMath(from drawing: PKDrawing, completion: @escaping (MathResult?) -> Void) {
        // 将绘图转换为图像
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // 创建数学识别请求 (iOS 15+)
        if #available(iOS 15.0, *) {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil)
                    return
                }
                
                // 处理识别结果
                let mathText = observations.compactMap { $0.topCandidates(1).first?.string }.joined()
                
                // 转换为 LaTeX (简化版)
                let latex = self.convertToLatex(mathText)
                
                let result = MathResult(
                    latex: latex,
                    confidence: observations.first?.topCandidates(1).first?.confidence ?? 0
                )
                
                DispatchQueue.main.async {
                    completion(result)
                }
            }
            
            // 配置为数学识别
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            
            // 使用自定义识别语言
            if #available(iOS 16.0, *) {
                request.customWords = ["+", "-", "×", "÷", "=", "∫", "∑", "π", "√", "∞"]
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        } else {
            completion(nil)
        }
    }
    
    /// 简单转换为 LaTeX
    private func convertToLatex(_ text: String) -> String {
        var latex = text
        
        // 替换常见数学符号
        latex = latex.replacingOccurrences(of: "×", with: "\\times ")
        latex = latex.replacingOccurrences(of: "÷", with: "\\div ")
        latex = latex.replacingOccurrences(of: "∫", with: "\\int ")
        latex = latex.replacingOccurrences(of: "∑", with: "\\sum ")
        latex = latex.replacingOccurrences(of: "π", with: "\\pi ")
        latex = latex.replacingOccurrences(of: "√", with: "\\sqrt ")
        latex = latex.replacingOccurrences(of: "∞", with: "\\infty ")
        
        return latex
    }
}
