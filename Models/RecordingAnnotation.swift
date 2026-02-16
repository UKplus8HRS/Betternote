import Foundation
import AVFoundation

/// 录音标注模型
/// 在录音的特定时间添加标注
struct RecordingAnnotation: Identifiable, Codable {
    var id: UUID
    var timestamp: TimeInterval  // 录音中的时间点 (秒)
    var text: String           // 标注文字
    var drawingData: Data?      // 标注绘图 (可选)
    var createdAt: Date
    
    init(id: UUID = UUID(), timestamp: TimeInterval, text: String, drawingData: Data? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.drawingData = drawingData
        self.createdAt = Date()
    }
}

/// 录音会话
/// 包含录音和所有标注
struct RecordingSession: Identifiable, Codable {
    var id: UUID
    var audioURL: URL?         // 录音文件路径
    var duration: TimeInterval // 录音时长
    var annotations: [RecordingAnnotation]
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID()) {
        self.id = id
        self.audioURL = nil
        self.duration = 0
        self.annotations = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// 在指定时间添加标注
    mutating func addAnnotation(at timestamp: TimeInterval, text: String, drawing: Data? = nil) {
        let annotation = RecordingAnnotation(
            timestamp: timestamp,
            text: text,
            drawingData: drawing
        )
        annotations.append(annotation)
        annotations.sort { $0.timestamp < $1.timestamp }
        modifiedAt = Date()
    }
    
    /// 删除标注
    mutating func removeAnnotation(id: UUID) {
        annotations.removeAll { $0.id == id }
        modifiedAt = Date()
    }
    
    /// 获取指定时间最近的标注
    func nearestAnnotation(at timestamp: TimeInterval, tolerance: TimeInterval = 2.0) -> RecordingAnnotation? {
        return annotations.first { abs($0.timestamp - timestamp) <= tolerance }
    }
    
    /// 格式化时间
    static func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
