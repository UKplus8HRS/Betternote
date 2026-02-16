import SwiftUI
import PencilKit

/// 增强版工具栏
/// 参考 GoodNotes/Notability 设计
struct EnhancedToolBar: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    
    let page: NotePage
    let pageIndex: Int
    
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .black
    @State private var strokeWidth: CGFloat = 3
    @State private var showingColorPicker = false
    @State private var showingTemplatePicker = false
    @State private var showingToolSettings = false
    
    // MARK: - 工具类型
    
    enum DrawingTool: String, CaseIterable {
        case pen = "钢笔"
        case highlighter = "荧光笔"
        case marker = "马克笔"
        case pencil = "铅笔"
        case eraser = "橡皮擦"
        case lasso = "套索"
        
        var icon: String {
            switch self {
            case .pen: return "pencil"
            case .highlighter: return "highlighter"
            case .marker: return "pencil.tip"
            case .pencil: return "pencil"
            case .eraser: return "eraser"
            case .lasso: return "lasso"
            }
        }
    }
    
    // MARK: - 预定义颜色
    
    let quickColors: [Color] = [
        .black, .gray, .red, .orange, .yellow, .green, .blue, .purple, .pink, .brown
    ]
    
    // MARK: - 主视图
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要工具栏
            mainToolbar
            
            // 颜色条 (展开时)
            if showingColorPicker {
                colorPickerBar
            }
            
            // 笔触设置 (展开时)
            if showingToolSettings {
                toolSettingsBar
            }
            
            // 模板选择 (展开时)
            if showingTemplatePicker {
                templatePickerBar
            }
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            setupCanvas()
        }
    }
    
    // MARK: - 主要工具栏
    
    private var mainToolbar: some View {
        HStack(spacing: 16) {
            // 工具选择器
            toolPicker
            
            Divider()
                .frame(height: 30)
            
            // 颜色按钮
            colorButton
            
            Divider()
                .frame(height: 30)
            
            // 笔触粗细
            strokeWidthButton
            
            Divider()
                .frame(height: 30)
            
            // 模板按钮
            templateButton
            
            Spacer()
            
            // 撤销/重做
            undoRedoButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - 工具选择器
    
    private var toolPicker: some View {
        Menu {
            ForEach(DrawingTool.allCases, id: \.self) { tool in
                Button(action: { selectedTool = tool }) {
                    Label(tool.rawValue, systemImage: tool.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedTool.icon)
                    .font(.system(size: 18))
                Text(selectedTool.rawValue)
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 颜色按钮
    
    private var colorButton: some View {
        Button(action: {
            showingColorPicker.toggle()
            showingToolSettings = false
            showingTemplatePicker = false
        }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                    )
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
        }
    }
    
    // MARK: - 笔触粗细按钮
    
    private var strokeWidthButton: some View {
        Button(action: {
            showingToolSettings.toggle()
            showingColorPicker = false
            showingTemplatePicker = false
        }) {
            HStack(spacing: 6) {
                Image(systemName: "lineweight")
                    .font(.system(size: 16))
                Text("\(Int(strokeWidth))")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
        }
    }
    
    // MARK: - 模板按钮
    
    private var templateButton: some View {
        Button(action: {
            showingTemplatePicker.toggle()
            showingColorPicker = false
            showingToolSettings = false
        }) {
            HStack(spacing: 6) {
                Image(systemName: page.templateType.iconName)
                    .font(.system(size: 16))
                Text(page.templateType.displayName)
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
        }
    }
    
    // MARK: - 撤销/重做
    
    private var undoRedoButtons: some View {
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
    
    // MARK: - 颜色选择条
    
    private var colorPickerBar: some View {
        HStack(spacing: 12) {
            ForEach(quickColors, id: \.self) { color in
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
            
            // 自定义颜色按钮
            Button(action: {
                // TODO: 打开系统颜色选择器
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 笔触设置条
    
    private var toolSettingsBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("粗细")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Slider(value: $strokeWidth, in: 1...30, step: 1)
                    .frame(maxWidth: 200)
                Text("\(Int(strokeWidth))")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 30)
            }
            
            // 透明度 (仅荧光笔)
            if selectedTool == .highlighter {
                HStack {
                    Text("透明度")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Slider(value: .constant(0.3), in: 0.1...0.5)
                        .frame(maxWidth: 200)
                    Text("30%")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 30)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 模板选择条
    
    private var templatePickerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(PageTemplateModel.templates) { templateModel in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: templateModel.backgroundColor) ?? .white)
                                .frame(width: 50, height: 65)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                            
                            // 模板预览
                            TemplatePreviewView(template: templateModel.template)
                                .frame(width: 40, height: 50)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    page.template == templateModel.template.rawValue ? Color.blue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        Text(templateModel.template.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        changeTemplate(templateModel.template)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 画布方法
    
    private func setupCanvas() {
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput
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
        }
    }
    
    private func updateTool() {
        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: strokeWidth)
        case .highlighter:
            canvasView.tool = PKInkingTool(.marker, color: UIColor(selectedColor).withAlphaComponent(0.3), width: strokeWidth * 3)
        case .marker:
            canvasView.tool = PKInkingTool(.marker, color: UIColor(selectedColor), width: strokeWidth * 1.5)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: UIColor(selectedColor), width: strokeWidth)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        case .lasso:
            canvasView.tool = PKLassoTool()
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
    
    private func changeTemplate(_ newTemplate: PageTemplate) {
        viewModel.changePageTemplate(newTemplate, at: pageIndex)
        showingTemplatePicker = false
    }
}

// MARK: - 模板预览视图

struct TemplatePreviewView: View {
    let template: PageTemplate
    
    var body: some View {
        ZStack {
            switch template {
            case .blank:
                Color.clear
            case .lined:
                VStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 4)
            case .grid:
                GeometryReader { geo in
                    Path { path in
                        let spacing: CGFloat = 8
                        for i in 0..<Int(geo.size.height / spacing) {
                            let y = CGFloat(i) * spacing
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        for i in 0..<Int(geo.size.width / spacing) {
                            let x = CGFloat(i) * spacing
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                }
            case .dotted:
                GeometryReader { geo in
                    let spacing: CGFloat = 8
                    ForEach(0..<Int(geo.size.height / spacing), id: \.self) { row in
                        ForEach(0..<Int(geo.size.width / spacing), id: \.self) { col in
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 2, height: 2)
                                .position(
                                    x: CGFloat(col) * spacing + spacing/2,
                                    y: CGFloat(row) * spacing + spacing/2
                                )
                        }
                    }
                }
            case .checklist:
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: 4) {
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                .frame(width: 10, height: 10)
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            case .calendar:
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 15)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Color 扩展

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
