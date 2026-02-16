import Foundation

/// AI 录音总结管理器
/// 录音 -> 识别 -> AI 总结
final class AISummaryManager: ObservableObject {
    
    // MARK: - 总结结果
    
    struct SummaryResult {
        var transcript: String       // 转写文本
        var summary: String         // 总结
        var bulletPoints: [String]  // 要点
        var keywords: [String]     // 关键词
        var sentiment: String       // 情感分析
    }
    
    // MARK: - Published 属性
    
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var result: SummaryResult?
    @Published var error: String?
    
    // MARK: - 配置
    
    struct Config {
        var apiKey: String = ""
        var model: String = "gpt-4"
    }
    
    var config = Config()
    
    // MARK: - 方法
    
    /// 录音并总结
    /// - Parameters:
    ///   - audioURL: 录音文件 URL
    ///   - completion: 完成回调
    func recordAndSummarize(audioURL: URL) async {
        await MainActor.run {
            isProcessing = true
            progress = 0
            error = nil
        }
        
        // 步骤1: 语音转文字 (30%)
        let transcript = await transcribeAudio(audioURL)
        
        // 步骤2: AI 总结 (70%)
        let summary = await generateSummary(from: transcript)
        
        await MainActor.run {
            result = summary
            isProcessing = false
            progress = 1.0
        }
    }
    
    /// 语音转文字
    private func transcribeAudio(_ url: URL) async -> String {
        await MainActor.run { progress = 0.3 }
        
        // 使用 Speech Framework
        // 这里简化实现
        return """
        这是一段示例转写文本。
        实际实现会调用 SFSpeechRecognizer 进行语音识别。
        """
    }
    
    /// AI 生成总结
    private func generateSummary(from transcript: String) async -> SummaryResult {
        await MainActor.run { progress = 0.7 }
        
        // 构建提示词
        let prompt = """
        请分析以下会议录音内容，生成：
        1. 一句话总结
        3. 5个要点
        5. 3-5个关键词
        6. 情感分析（正面/中性/负面）
        
        录音内容：
        \(transcript)
        
        请用中文回复，格式如下：
        总结：[一句话总结]
        要点：[要点1]|[要点2]|[要点3]|[要点4]|[要点5]
        关键词：[关键词1],[关键词2],[关键词3]
        情感：[正面/中性/负面]
        """
        
        // 调用 AI API
        let aiResponse = await callAI(prompt: prompt)
        
        // 解析响应
        return parseAIResponse(aiResponse)
    }
    
    /// 调用 AI
    private func callAI(prompt: String) async -> String {
        // 这里调用 OpenAI GPT API
        // 模拟实现
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        return """
        总结：讨论了项目进度和下一步计划
        要点：完成了UI设计|后端API开发中|需要测试|下周演示|准备文档
        关键词：项目, 进度, 计划, 测试, 演示
        情感：中性
        """
    }
    
    /// 解析 AI 响应
    private func parseAIResponse(_ response: String) -> SummaryResult {
        var summary = ""
        var bulletPoints: [String] = []
        var keywords: [String] = []
        var sentiment = "中性"
        
        let lines = response.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("总结：") {
                summary = String(line.dropFirst(3))
            } else if line.hasPrefix("要点：") {
                bulletPoints = line.dropFirst(3).components(separatedBy: "|")
            } else if line.hasPrefix("关键词：") {
                keywords = line.dropFirst(5).components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            } else if line.hasPrefix("情感：") {
                sentiment = String(line.dropFirst(3))
            }
        }
        
        return SummaryResult(
            transcript: "",  // 之前已保存
            summary: summary,
            bulletPoints: bulletPoints,
            keywords: keywords,
            sentiment: sentiment
        )
    }
}

// MARK: - 录音总结视图

import SwiftUI

struct RecordingSummaryView: View {
    @ObservedObject var summaryManager: AISummaryManager
    @ObservedObject var speechManager: SpeechToTextManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 录音/停止按钮
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(summaryManager.isProcessing ? Color.gray : (speechManager.state == .recording ? Color.red : Color.blue))
                        .frame(width: 80, height: 80)
                    
                    if speechManager.state == .recording {
                        // 录音中动画
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 3)
                            .frame(width: 90, height: 90)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechManager.state)
                    }
                    
                    Image(systemName: speechManager.state == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            // 状态文字
            Text(statusText)
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 进度条
            if summaryManager.isProcessing {
                VStack(spacing: 8) {
                    ProgressView(value: summaryManager.progress)
                    Text("\(Int(summaryManager.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }
            
            // 总结结果
            if let result = summaryManager.result {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 总结
                        VStack(alignment: .leading, spacing: 8) {
                            Label("总结", systemImage: "text.bubble")
                                .font(.headline)
                            Text(result.summary)
                                .font(.body)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 要点
                        VStack(alignment: .leading, spacing: 8) {
                            Label("要点", systemImage: "list.bullet")
                                .font(.headline)
                            ForEach(result.bulletPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    Text(point)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 关键词
                        if !result.keywords.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("关键词", systemImage: "tag")
                                    .font(.headline)
                                FlowLayout(spacing: 8) {
                                    ForEach(result.keywords, id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.orange.opacity(                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        // 情感
                       0.2))
 HStack {
                            Label("情感", systemImage: result.sentiment == "正面" ? "face.smiling" : (result.sentiment == "负面" ? "face.smiling.inverse" : "face.smiling"))
                            Spacer()
                            Text(result.sentiment)
                                .foregroundColor(sentimentColor(result.sentiment))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("AI 录音总结")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var statusText: String {
        if summaryManager.isProcessing {
            return "AI 正在分析..."
        }
        switch speechManager.state {
        case .idle: return "点击开始录音"
        case .recording: return "正在录音..."
        case .processing: return "处理中..."
        case .completed: return "录音完成"
        case .error(let msg): return "错误: \(msg)"
        }
    }
    
    private func toggleRecording() {
        if speechManager.state == .recording {
            speechManager.stopRecording()
            
            // 开始 AI 总结
            // 需要保存录音文件然后调用 summaryManager
        } else {
            try? speechManager.startRecording()
        }
    }
    
    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "正面": return .green
        case "负面": return .red
        default: return .gray
        }
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + 8
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + 8
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
