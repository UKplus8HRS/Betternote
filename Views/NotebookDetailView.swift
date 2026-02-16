import SwiftUI

/// 笔记本详情视图
/// 显示笔记本内的所有页面，参考 GoodNotes 缩略图导航
/// 支持双页模式、单页模式切换
struct NotebookDetailView: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    let notebook: Notebook
    
    @State private var showingAddPage = false
    @State private var isGridView = true  // 网格视图/列表视图切换
    @State private var viewMode: ViewMode = .single  // 单页/双页模式
    @State private var showingPageThumbnails = true  // 显示侧边缩略图
    
    /// 视图模式
    enum ViewMode: String, CaseIterable {
        case single = "单页"
        case double = "双页"
        case scroll = "滚动"
        
        var icon: String {
            switch self {
            case .single: return "doc"
            case .double: return "rectangle.split.2x1"
            case .scroll: return "arrow.up.arrow.down"
            }
        }
    }
    
    /// 网格布局
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 15)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            topToolbar
            
            Divider()
            
            // 主要内容区
            HStack(spacing: 0) {
                // 侧边缩略图栏 (可选)
                if showingPageThumbnails {
                    thumbnailSidebar
                        .frame(width: 100)
                        .transition(.move(edge: .leading))
                }
                
                // 笔记内容
                mainContent
            }
        }
        .navigationTitle(notebook.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                moreMenu
            }
        }
    }
    
    // MARK: - 顶部工具栏
    
    private var topToolbar: some View {
        HStack {
            // 页面数量
            Text("\(notebook.pages.count) 页")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 视图模式切换
            Picker("视图模式", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
            
            // 缩略图栏开关
            Button(action: { withAnimation { showingPageThumbnails.toggle() }}) {
                Image(systemName: showingPageThumbnails ? "sidebar.left" : "sidebar.left")
                    .foregroundColor(showingPageThumbnails ? .blue : .secondary)
            }
            
            // 添加页面按钮
            Button(action: { viewModel.addPage() }) {
                Image(systemName: "plus")
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 侧边缩略图栏
    
    private var thumbnailSidebar: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 4) {
                        // 缩略图
                        PageThumbnailView(
                            page: page,
                            pageNumber: index + 1,
                            isSelected: index == viewModel.selectedPageIndex,
                            size: 70
                        )
                        .onTapGesture {
                            viewModel.selectPage(at: index)
                        }
                        
                        // 页码
                        Text("\(index + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 主要内容
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewMode {
        case .single:
            singlePageView
        case .double:
            doublePageView
        case .scroll:
            scrollPageView
        }
    }
    
    // 单页模式
    private var singlePageView: some View {
        Group {
            if let page = viewModel.selectedPage {
                NoteCanvasView(page: page, pageIndex: viewModel.selectedPageIndex)
            } else {
                emptyState
            }
        }
    }
    
    // 双页模式
    private var doublePageView: some View {
        HStack(spacing: 4) {
            // 当前页
            if let currentPage = viewModel.selectedPage {
                NoteCanvasView(page: currentPage, pageIndex: viewModel.selectedPageIndex)
            }
            
            // 下一页 (如果存在)
            if viewModel.selectedPageIndex + 1 < notebook.pages.count {
                let nextPage = notebook.pages[viewModel.selectedPageIndex + 1]
                NoteCanvasView(page: nextPage, pageIndex: viewModel.selectedPageIndex + 1)
            } else {
                // 空页面
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    Text("空白页")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // 滚动模式
    private var scrollPageView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                        NoteCanvasView(page: page, pageIndex: index)
                            .frame(height: 600)
                            .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.selectedPageIndex) { index in
                withAnimation {
                    proxy.scrollTo(index, anchor: .top)
                }
            }
        }
    }
    
    // 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无页面")
                .font(.headline)
            Button("添加页面") {
                viewModel.addPage()
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - 更多菜单
    
    private var moreMenu: some View {
        Menu {
            Button("重命名") {
                // TODO: 实现重命名
            }
            Button("更改颜色") {
                // TODO: 更改颜色
            }
            Divider()
            Button("导出 PDF") {
                // TODO: 导出 PDF
            }
            Button("导入 PDF") {
                // TODO: 导入 PDF
            }
            Divider()
            Button("笔记本设置") {
                // TODO: 笔记本设置
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// MARK: - 页面缩略图视图

struct PageThumbnailView: View {
    let page: NotePage
    let pageNumber: Int
    let isSelected: Bool
    var size: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: page.backgroundColor) ?? .white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // 模板预览
                TemplatePreviewView(template: page.templateType)
                    .scaleEffect(0.3)
                
                // 绘制内容
                if let thumbnailData = page.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(2)
                }
            }
            .frame(width: size, height: size * 1.4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - 预览

struct NotebookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let notebook = Notebook(title: "数学笔记", coverColor: "blue")
        return NotebookDetailView(notebook: notebook)
            .environmentObject(NotebookViewModel())
    }
}
