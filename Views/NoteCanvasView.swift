import SwiftUI
import PencilKit

/// 笔记手写画布视图 (增强版)
/// 核心组件，使用 PencilKit 实现手写功能
/// 支持手势操作：缩放、旋转、翻页
struct NoteCanvasView: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    let page: NotePage
    let pageIndex: Int
    
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var gestureManager = GestureManager()
    @State private var showingToolBar = true
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Angle = .zero
    
    // MARK: - 页面模板背景
    
    var templateBackground: some View {
        ZStack {
            // 背景色
            Color(hex: page.backgroundColor) ?? .white
            
            // 模板网格
            TemplatePreviewView(template: page.templateType)
                .scaleEffect(gestureManager.scale)
        }
    }
    
    // MARK: - 主视图
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                templateBackground
                    .clipped()
                
                // 画布
                CanvasRepresentable(
                    canvasView: $canvasView,
                    drawing: $drawing,
                    page: page,
                    pageIndex: pageIndex,
                    onDrawingChanged: { newDrawing in
                        viewModel.updatePageDrawing(newDrawing, at: pageIndex)
                    }
                )
                .scaleEffect(gestureManager.scale)
                .rotationEffect(gestureManager.rotation)
                .gesture(combinedGesture)
                .gesture(doubleTapGesture)
                
                // 工具栏
                VStack {
                    Spacer()
                    if showingToolBar {
                        EnhancedToolBar(
                            page: page,
                            pageIndex: pageIndex
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            setupCanvas()
        }
        .onChange(of: pageIndex) { _ in
            loadPageDrawing()
        }
        .onTapGesture {
            showingToolBar.toggle()
        }
    }
    
    // MARK: - 手势
    
    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    gestureManager.handleScale(delta)
                }
                .onEnded { _ in
                    lastScale = 1.0
                },
            RotationGesture()
                .onChanged { angle in
                    let delta = angle - lastRotation
                    lastRotation = angle
                    gestureManager.rotation += delta
                }
                .onEnded { _ in
                    lastRotation = .zero
                }
        )
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if gestureManager.handleDoubleTap() {
                    lastScale = 1.0
                    lastRotation = .zero
                }
            }
    }
    
    // MARK: - 画布方法
    
    private func setupCanvas() {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.minimumZoomScale = gestureManager.minScale
        canvasView.maximumZoomScale = gestureManager.maxScale
        
        loadPageDrawing()
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
        // 工具设置由 EnhancedToolBar 处理
    }
}

// MARK: - Canvas Representable (更新版)

/// UIViewRepresentable 包装 PKCanvasView
struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing
    let page: NotePage
    let pageIndex: Int
    let onDrawingChanged: (PKDrawing) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
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
