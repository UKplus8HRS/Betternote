import Foundation

/// AI 功能管理器
/// 提供各种 AI 辅助功能
final class AIManager: ObservableObject {
    
    // MARK: - AI 功能类型
    
    enum AIFeature {
        case handwritingRecognition  // 手写识别
        case textSummary            // 文本摘要
        case mathRecognition        // 数学公式识别
        case shapeDetection         // 图形识别
        case voiceTranscription     // 语音转文字
        case translation           // 翻译
        case searchEnhancement     // 智能搜索
        case contentSuggestion      // 内容建议
    }
    
    // MARK: - 配置
    
    /// AI 服务配置
    struct AIConfig {
        var apiKey: String = ""
        var endpoint: String = ""
        var model: String = "gpt-4"
    }
    
    @Published var config: AIConfig = AIConfig()
    @Published var isProcessing: Bool = false
    
    // MARK: - 方法
    
    /// 配置 AI 服务
    func configure(apiKey: String, endpoint: String = "", model: String = "gpt-4") {
        config.apiKey = apiKey
        config.endpoint = endpoint
        config.model = model
    }
    
    /// 检查是否已配置
    var isConfigured: Bool {
        !config.apiKey.isEmpty
    }
}

// MARK: - 手写识别结果

struct HandwritingRecognitionResult {
    var text: String
    var confidence: Double
    var boundingBoxes: [CGRect]
}

// MARK: - 数学公式识别结果

struct MathRecognitionResult {
    var latex: String      // LaTeX 格式
    var image: Data?       // 公式图片
    var confidence: Double
}

// MARK: - 形状识别结果

struct ShapeRecognitionResult {
    enum ShapeType {
        case rectangle
        case circle
        case line
        case arrow
        case unknown
    }
    
    var type: ShapeType
    var points: [CGPoint]
    var bounds: CGRect
    var confidence: Double
}

// MARK: - 文本摘要结果

struct SummaryResult {
    var summary: String
    var keywords: [String]
    var bulletPoints: [String]
}
