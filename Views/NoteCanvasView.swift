import SwiftUI
import PencilKit

/// 笔记手写画布视图
/// 核心组件，使用 PencilKit 实现手写功能
struct NoteCanvasView: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    let page: NotePage
    let pageIndex: Int
    
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var selectedTool: ToolType = .pen
    @State private var selectedColor: Color = .black
    @State private var strokeWidth: CGFloat = 3
    
    /// 工具类型
    enum ToolType: String, CaseIterable {
        case pen = "钢笔"
        case highlighter = "荧光笔"
        case eraser = "橡皮擦"
        
        var icon: String {
            switch self {
            case .pen: return "pencil"
            case .highlighter: return "highlighter"
            case .eraser: return "eraser"
            }
        }
    }
    
    /// 预定义颜色
    let colors: [Color] = [
        .black, .gray, .red, .orange, .yellow, .green, .blue, .purple, .pink, .brown
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolBar
            
            Divider()
            
            // 手写画布
            CanvasRepresentable(
                canvasView: $canvasView,
                drawing: $drawing,
                tool: selectedTool,
                color: selectedColor,
                strokeWidth: strokeWidth,
                onDrawingChanged: { newDrawing in
                    viewModel.updatePageDrawing(newDrawing, at: pageIndex)
                }
            )
        }
        .onAppear {
            setupCanvas()
        }
        .onChange(of: pageIndex) { _ in
            loadPageDrawing()
        }
    }
    
    // MARK: - 工具栏
    
    private var toolBar: some View {
        HStack(spacing: 20) {
            // 工具选择
            HStack(spacing: 12) {
                ForEach(ToolType.allCases, id: \.self) { tool in
                    Button(action: { selectedTool = tool }) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedTool == tool ? .blue : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                selectedTool == tool ?
                                Color.blue.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(8)
                    }
                }
            }
            
            Divider()
                .frame(height: 30)
            
            // 颜色选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColor = color
                                updateTool()
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
                .frame(height: 30)
            
            // 笔触粗细
            HStack(spacing: 8) {
                Image(systemName: "lineweight")
                    .foregroundColor(.secondary)
                
                Slider(value: $strokeWidth, in: 1...20, step: 1)
                    .frame(width: 80)
                    .onChange(of: strokeWidth) { _ in
                        updateTool()
                    }
            }
            
            Spacer()
            
            // 撤销/重做
            HStack(spacing: 12) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.canUndo ? .primary : .secondary.opacity(0.5))
                }
                .disabled(!viewModel.canUndo)
                
                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.canRedo ? .primary : .secondary.opacity(0.5))
                }
                .disabled(!viewModel.canRedo)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 画布方法
    
    private func setupCanvas() {
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput // 支持 Apple Pencil 和手指
        
        // 加载已有绘制
        loadPageDrawing()
        
        // 应用当前工具
        updateTool()
    }
    
    private func loadPageDrawing() {
        if let drawingData = page.drawingData {
            do {
                drawing = try PKDrawing(data: drawingData)
                canvasView.drawing = drawing
            } catch {
                print("加载绘制数据失败: \(error)")
            }
        } else {
            drawing = PKDrawing()
            canvasView.drawing = drawing
        }
    }
    
    private func updateTool() {
        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: strokeWidth)
        case .highlighter:
            canvasView.tool = PKInkingTool(.marker, color: UIColor(selectedColor).withAlphaComponent(0.3), width: strokeWidth * 3)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        }
    }
    
    private func undo() {
        if let previousDrawing = viewModel.undo(drawing: drawing) {
            drawing = previousDrawing
            canvasView.drawing = drawing
        }
    }
    
    private func redo() {
        if let nextDrawing = viewModel.redo(drawing: drawing) {
            drawing = nextDrawing
            canvasView.drawing = drawing
        }
    }
}

// MARK: - Canvas Representable

/// UIViewRepresentable 包装 PKCanvasView
struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing
    let tool: NoteCanvasView.ToolType
    let color: Color
    let strokeWidth: CGFloat
    let onDrawingChanged: (PKDrawing) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 同步 drawing 变化
        if uiView.drawing != drawing {
            drawing = uiView.drawing
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasRepresentable
        
        init(_ parent: CanvasRepresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged(canvasView.drawing)
        }
    }
}

// MARK: - 预览

struct NoteCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let page = NotePage()
        return NoteCanvasView(page: page, pageIndex: 0)
            .environmentObject(NotebookViewModel())
            .frame(height: 600)
    }
}
