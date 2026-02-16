import Foundation

/// AI 智能助手
/// 提供内容建议、润色、翻译等功能
final class AIAssistant: ObservableObject {
    
    // MARK: - 功能类型
    
    enum AssistantFeature: String, CaseIterable {
        case improveWriting = "润色"
        case translate = "翻译"
        case summarize = "摘要"
        case expand = "扩展"
        case fixSpelling = "纠错"
        case extractContent = "提取"
        
        var icon: String {
            switch self {
            case .improveWriting: return "wand.and.stars"
            case .translate: return "globe"
            case .summarize: return "text.badge.checkmark"
            case .expand: return "arrow.up.left.and.arrow.down.right"
            case .fixSpelling: return "checkmark.circle"
            case .extractContent: return "doc.text.magnifyingglass"
            }
        }
    }
    
    // MARK: - 请求/响应
    
    struct AIRequest {
        var feature: AssistantFeature
        var text: String
        var targetLanguage: String?  // 用于翻译
        var context: String?         // 上下文
    }
    
    struct AIResponse {
        var text: String
        var confidence: Double
        var suggestions: [String]
    }
    
    // MARK: - Published 属性
    
    @Published var isProcessing: Bool = false
    @Published var lastError: String?
    @Published var config: AIConfig = AIConfig()
    
    // MARK: - AI 配置
    
    struct AIConfig {
        var apiKey: String = ""
        var endpoint: String = "https://api.openai.com/v1/chat/completions"
        var model: String = "gpt-4"
    }
    
    // MARK: - 方法
    
    /// 配置 AI
    func configure(apiKey: String, model: String = "gpt-4") {
        config.apiKey = apiKey
        config.model = model
    }
    
    /// 处理请求
    func process(_ request: AIRequest) async -> AIResponse? {
        guard !config.apiKey.isEmpty else {
            await MainActor.run {
                lastError = "请配置 API Key"
            }
            return nil
        }
        
        await MainActor.run {
            isProcessing = true
            lastError = nil
        }
        
        // 构建提示词
        let prompt = buildPrompt(for: request)
        
        // 调用 API (这里需要你自己实现实际的 API 调用)
        do {
            let response = try await callAI(prompt: prompt)
            
            await MainActor.run {
                isProcessing = false
            }
            
            return AIResponse(
                text: response,
                confidence: 0.9,
                suggestions: []
            )
        } catch {
            await MainActor.run {
                lastError = error.localizedDescription
                isProcessing = false
            }
            return nil
        }
    }
    
    /// 构建提示词
    private func buildPrompt(for request: AIRequest) -> String {
        var prompt = ""
        
        switch request.feature {
        case .improveWriting:
            prompt = "请润色以下文字，使其更流畅、专业：\n\n\(request.text)"
            
        case .translate:
            let targetLang = request.targetLanguage ?? "英文"
            prompt = "请将以下文字翻译成\(targetLang)：\n\n\(request.text)"
            
        case .summarize:
            prompt = "请用简洁的语言总结以下内容的要点：\n\n\(request.text)"
            
        case .expand:
            prompt = "请扩展以下内容，添加更多细节：\n\n\(request.text)"
            
        case .fixSpelling:
            prompt = "请检查以下文字的拼写和语法错误：\n\n\(request.text)"
            
        case .extractContent:
            prompt = "请从以下内容中提取关键信息：\n\n\(request.text)"
        }
        
        if let context = request.context {
            prompt += "\n\n上下文：\(context)"
        }
        
        return prompt
    }
    
    /// 调用 AI API
    private func callAI(prompt: String) async throws -> String {
        // 这里需要实现实际的 API 调用
        // 可以使用 URLSession 调用 OpenAI 或其他 AI 服务
        
        // 模拟响应
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return "这是 AI 的模拟响应。请配置实际的 API Key。"
    }
}

// MARK: - AI 助手视图

import SwiftUI

struct AIAssistantPanel: View {
    @ObservedObject var assistant: AIAssistant
    @State private var inputText: String = ""
    @State private var selectedFeature: AIAssistant.AssistantFeature = .improveWriting
    @State private var outputText: String = ""
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 功能选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AIAssistant.AssistantFeature.allCases, id: \.self) { feature in
                        FeatureButton(
                            feature: feature,
                            isSelected: selectedFeature == feature,
                            action: { selectedFeature = feature }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("输入内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $inputText)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // 处理按钮
            Button(action: processContent) {
                HStack {
                    if assistant.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(assistant.isProcessing ? "处理中..." : "开始处理")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputText.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || assistant.isProcessing)
            .padding(.horizontal)
            
            // 输出区域
            if !outputText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("结果")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(outputText)
                            .textSelection(.enabled)
                    }
                    .frame(height: 120)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // 操作按钮
                    HStack {
                        Button("复制") {
                            UIPasteboard.general.string = outputText
                        }
                        
                        Button("插入笔记") {
                            // 插入到当前笔记
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 错误提示
            if let error = assistant.lastError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingSettings) {
            AISettingsView(assistant: assistant)
        }
        .navigationTitle("AI 助手")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
    
    private func processContent() {
        let request = AIAssistant.AIRequest(
            feature: selectedFeature,
            text: inputText
        )
        
        Task {
            if let response = await assistant.process(request) {
                outputText = response.text
            }
        }
    }
}

struct FeatureButton: View {
    let feature: AIAssistant.AssistantFeature
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: feature.icon)
                    .font(.system(size: 20))
                Text(feature.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
        }
    }
}

struct AISettingsView: View {
    @ObservedObject var assistant: AIAssistant
    @State private var apiKey: String = ""
    @State private var model: String = "gpt-4"
    
    var body: some View {
        Form {
            Section("API 配置") {
                SecureField("API Key", text: $apiKey)
                Picker("模型", selection: $model) {
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
            }
            
            Section {
                Button("保存") {
                    assistant.configure(apiKey: apiKey, model: model)
                }
            }
        }
    }
}
