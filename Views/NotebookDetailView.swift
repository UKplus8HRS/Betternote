import SwiftUI

/// 笔记本详情视图
/// 显示笔记本内的所有页面，参考 GoodNotes 缩略图导航
struct NotebookDetailView: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    let notebook: Notebook
    
    @State private var showingAddPage = false
    @State private var isGridView = true  // 网格视图/列表视图切换
    
    /// 网格布局
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 15)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                // 页面数量
                Text("\(notebook.pages.count) 页")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 视图切换按钮
                Button(action: { isGridView.toggle() }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .foregroundColor(.secondary)
                }
                
                // 添加页面按钮
                Button(action: { viewModel.addPage() }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // 页面列表/网格
            if isGridView {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                            PageThumbnailView(
                                page: page,
                                pageNumber: index + 1,
                                isSelected: index == viewModel.selectedPageIndex
                            )
                            .onTapGesture {
                                viewModel.selectPage(at: index)
                            }
                            .contextMenu {
                                Button("复制页面") {
                                    // TODO: 实现复制
                                }
                                Button("删除页面", role: .destructive) {
                                    viewModel.deletePage(at: index)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // 列表视图
                List {
                    ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                        HStack {
                            // 缩略图
                            PageThumbnailView(
                                page: page,
                                pageNumber: index + 1,
                                isSelected: index == viewModel.selectedPageIndex,
                                size: 60
                            )
                            .frame(width: 60, height: 80)
                            
                            Text("第 \(index + 1) 页")
                                .font(.headline)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectPage(at: index)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deletePage(at: index)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Divider()
            
            // 底部画布视图 (核心手写区域)
            if let page = viewModel.selectedPage {
                NoteCanvasView(
                    page: page,
                    pageIndex: viewModel.selectedPageIndex
                )
                .frame(minHeight: 400)
            }
        }
        .navigationTitle(notebook.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

/// 页面缩略图视图
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
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // 如果有缩略图显示缩略图
                if let thumbnailData = page.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                } else {
                    // 默认空白页面
                    VStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                }
            }
            .frame(width: size, height: size * 1.4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            // 页码
            Text("\(pageNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
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
