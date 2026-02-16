import Foundation
import Speech
import AVFoundation

/// 语音转文字管理器
/// 使用 Apple 的 Speech 框架进行实时语音识别
final class SpeechToTextManager: NSObject, ObservableObject {
    
    // MARK: - 状态
    
    enum RecognitionState {
        case idle
        case recording
        case processing
        case completed
        case error(String)
    }
    
    @Published var state: RecognitionState = .idle
    @Published var transcribedText: String = ""
    @Published var isAuthorized: Bool = false
    
    // MARK: - 私有属性
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - 初始化
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        super.init()
        speechRecognizer?.delegate = self
    }
    
    // MARK: - 授权
    
    /// 请求语音识别授权
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.isAuthorized = (status == .authorized)
                    continuation.resume(returning: self.isAuthorized)
                }
            }
        }
    }
    
    // MARK: - 录音
    
    /// 开始语音识别
    func startRecording() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            state = .error("语音识别不可用")
            return
        }
        
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            state = .error("无法创建识别请求")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 识别中文
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // 开始识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if isFinal {
                    self.state = .completed
                } else if let error = error {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
        
        // 配置音频输入
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        state = .recording
    }
    
    /// 停止语音识别
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        if case .recording = state {
            state = .completed
        }
    }
    
    /// 重置
    func reset() {
        stopRecording()
        transcribedText = ""
        state = .idle
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechToTextManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            state = .error("语音识别不可用")
        }
    }
}

// MARK: - 语音输入视图

import SwiftUI

struct VoiceInputView: View {
    @ObservedObject var speechManager: SpeechToTextManager
    var onTextRecognized: (String) -> Void
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 录音按钮
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(speechManager.state == .recording ? Color.red : Color.blue)
                        .frame(width: 60, height: 60)
                    
                    if speechManager.state == .recording {
                        // 录音中动画
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            .frame(width: 70, height: 70)
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechManager.state)
                    }
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            // 状态文字
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 转写结果
            if !speechManager.transcribedText.isEmpty {
                Text(speechManager.transcribedText)
                    .font(.body)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(maxHeight: 150)
            }
            
            // 操作按钮
            if speechManager.state == .completed && !speechManager.transcribedText.isEmpty {
                HStack {
                    Button("重新录音") {
                        speechManager.reset()
                    }
                    
                    Button("插入笔记") {
                        onTextRecognized(speechManager.transcribedText)
                        speechManager.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .alert("需要语音识别权限", isPresented: $showingPermissionAlert) {
            Button("设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在设置中启用语音识别权限")
        }
    }
    
    private var statusText: String {
        switch speechManager.state {
        case .idle:
            return "点击开始录音"
        case .recording:
            return "正在录音..."
        case .processing:
            return "处理中..."
        case .completed:
            return "录音完成"
        case .error(let message):
            return "错误: \(message)"
        }
    }
    
    private func toggleRecording() {
        if speechManager.state == .recording {
            speechManager.stopRecording()
        } else {
            Task {
                if speechManager.isAuthorized {
                    try? speechManager.startRecording()
                } else {
                    let authorized = await speechManager.requestAuthorization()
                    if authorized {
                        try? speechManager.startRecording()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        }
    }
}
