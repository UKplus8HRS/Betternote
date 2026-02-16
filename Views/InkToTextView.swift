import SwiftUI
import PencilKit

/// 墨迹转文字视图
/// 将手写文字转换为可编辑文本
struct InkToTextView: View {
    @ObservedObject var manager: InkToTextManager
    @Environment(\.dismiss) var dismiss
    
    let drawing: PKDrawing
    @State private var showingResult: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 绘图预览
                VStack(alignment: .leading, spacing: 8) {
                    Text("手写内容预览")
                        .font(.headline)
                    
                    Image(uiImage: drawing.image(from: drawing.bounds, scale: 1.0))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 说明
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    Text("点击下方按钮开始识别")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("手写文字将转换为可编辑文本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 识别按钮
                Button(action: startConversion) {
                    HStack {
                        if manager.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(manager.isProcessing ? "识别中..." : "开始识别")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(manager.isProcessing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(manager.isProcessing)
                
                // 进度条
                if manager.isProcessing {
                    VStack(spacing: 4) {
                        ProgressView(value: manager.progress)
                        Text("\(Int(manager.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 错误提示
                if let error = manager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("墨迹转文字")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                if let result = manager.result {
                    InkToTextResultView(result: result, onInsert: insertText)
                }
            }
        }
    }
    
    private func startConversion() {
        Task {
            let result = await manager.convertToText(drawing)
            
            if result != nil {
                showingResult = true
            }
        }
    }
    
    private func insertText(_ text: String) {
        // 将文字插入到笔记
        dismiss()
    }
}

// MARK: - 识别结果视图

struct InkToTextResultView: View {
    let result: InkToTextManager.ConversionResult
    let onInsert: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var editedText: String = ""
    @State private var showingCopySuccess: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 统计信息
                HStack {
                    VStack {
                        Text("\(result.words.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("单词数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(result.text.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("字符数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(Int(result.words.filter { $0.confidence > 0.8 }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("高置信度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 识别结果
                VStack(alignment: .leading, spacing: 8) {
                    Text("识别结果")
                        .font(.headline)
                    
                    TextEditor(text: $editedText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: copyText) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("复制")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    Button(action: { onInsert(editedText) }) {
                        HStack {
                            Image(systemName: "text.insert")
                            Text("插入笔记")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                if showingCopySuccess {
                    Text("已复制到剪贴板")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedText = result.text
            }
        }
    }
    
    private func copyText() {
        UIPasteboard.general.string = editedText
        showingCopySuccess = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopySuccess = false
        }
    }
}
