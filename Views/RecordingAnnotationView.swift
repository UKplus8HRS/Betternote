import SwiftUI
import PencilKit

/// 录音标注视图
/// 录音时可添加文字/绘图标注
struct RecordingAnnotationView: View {
    @ObservedObject var manager: RecordingAnnotationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingTextAnnotation: Bool = false
    @State private var annotationText: String = ""
    @State private var isDrawingMode: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 录音波形和时间
            recordingHeader
            
            Divider()
            
            // 标注列表
            annotationList
            
            Divider()
            
            // 底部控制栏
            controlBar
        }
        .navigationTitle("录音标注")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingTextAnnotation) {
            textAnnotationSheet
        }
    }
    
    // MARK: - 录音头部
    
    private var recordingHeader: some View {
        VStack(spacing: 16) {
            // 录音按钮
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(manager.state == .recording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                    
                    if manager.state == .recording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // 时间显示
            Text(RecordingSession.formatTime(manager.currentTime))
                .font(.system(size: 48, weight: .light, design: .monospaced))
            
            // 音量指示器
            if manager.state == .recording {
                AudioLevelIndicator(level: manager.audioLevel)
                    .frame(height: 20)
            }
            
            // 状态文字
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - 标注列表
    
    private var annotationList: some View {
        Group {
            if manager.session.annotations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("录音时点击添加标注")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(manager.session.annotations) { annotation in
                            AnnotationRow(
                                annotation: annotation,
                                isPlaying: manager.currentTime >= annotation.timestamp && 
                                          manager.currentTime < annotation.timestamp + 2,
                                onTap: {
                                    try? manager.play(from: annotation.timestamp)
                                },
                                onDelete: {
                                    manager.session.removeAnnotation(id: annotation.id)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 控制栏
    
    private var controlBar: some View {
        HStack(spacing: 20) {
            // 添加文字标注
            Button(action: { showingTextAnnotation = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 24))
                    Text("文字")
                        .font(.caption)
                }
            }
            .disabled(manager.state != .recording)
            
            // 添加绘图标注
            Button(action: { isDrawingMode.toggle() }) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 24))
                    Text("绘图")
                        .font(.caption)
                }
            }
            .disabled(manager.state != .recording)
            .foregroundColor(isDrawingMode ? .blue : .primary)
            
            Spacer()
            
            // 播放/暂停
            if manager.state == .stopped {
                Button(action: playOrPause) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 文字标注表单
    
    private var textAnnotationSheet: View {
        NavigationView {
            VStack(spacing: 20) {
                Text("在 \(RecordingSession.formatTime(manager.currentTime)) 添加标注")
                    .font(.headline)
                
                TextField("输入标注内容", text: $annotationText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加标注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        annotationText = ""
                        showingTextAnnotation = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        manager.addTextAnnotation(annotationText)
                        annotationText = ""
                        showingTextAnnotation = false
                    }
                    .disabled(annotationText.isEmpty)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private var statusText: String {
        switch manager.state {
        case .idle: return "点击开始录音"
        case .recording: return "正在录音..."
        case .paused: return "已暂停"
        case .stopped: return "录音完成"
        }
    }
    
    private func toggleRecording() {
        switch manager.state {
        case .idle:
            try? manager.startRecording()
        case .recording:
            manager.pauseRecording()
        case .paused:
            manager.resumeRecording()
        case .stopped:
            manager.reset()
        }
    }
    
    private func playOrPause() {
        try? manager.play()
    }
}

// MARK: - 标注行

struct AnnotationRow: View {
    let annotation: RecordingAnnotation
    let isPlaying: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 时间
            Text(RecordingSession.formatTime(annotation.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(annotation.text)
                    .font(.body)
                
                if annotation.drawingData != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.tip")
                            .font(.caption)
                        Text("含绘图")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 播放按钮
            Button(action: onTap) {
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isPlaying ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("从此处播放", action: onTap)
            Button("删除", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - 音量指示器

struct AudioLevelIndicator: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { index in
                    let threshold = Float(index) / 20.0
                    Rectangle()
                        .fill(level > threshold ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: (geo.size.width - 38) / 20)
                        .cornerRadius(2)
                }
            }
        }
    }
}
