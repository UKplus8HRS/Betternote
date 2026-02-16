import SwiftUI

/// 大纲模式视图
/// 左边显示大纲/目录，右边显示笔记页面
struct OutlineModeView: View {
    @ObservedObject var viewModel: NotebookViewModel
    let notebook: Notebook
    
    @State private var outline: NotebookOutline
    @State private var selectedItemId: UUID?
    @State private var isEditing: Bool = false
    @State private var showingAddItem: Bool = false
    @State private var newItemTitle: String = ""
    
    init(notebook: Notebook, viewModel: NotebookViewModel) {
        self.notebook = notebook
        self.viewModel = viewModel
        self._outline = State(initialValue: NotebookOutline.generate(from: notebook))
    }
    
    var body: some View {
        NavigationSplitView {
            // 左边大纲栏
            outlineSidebar
        } detail: {
            // 右边笔记内容
            if let selectedId = selectedItemId,
               let item = outline.items.first(where: { $0.id == selectedId }) {
                NoteCanvasView(
                    page: notebook.pages[item.pageIndex],
                    pageIndex: item.pageIndex
                )
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - 大纲侧边栏
    
    private var outlineSidebar: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("大纲")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
                
                Button(action: regenerateOutline) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()
            
            Divider()
            
            // 大纲列表
            if outline.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无大纲")
                        .foregroundColor(.secondary)
                    Button("生成大纲") {
                        regenerateOutline()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedItemId) {
                    ForEach(outline.items) { item in
                        OutlineItemRow(
                            item: item,
                            isSelected: selectedItemId == item.id,
                            onTap: {
                                selectedItemId = item.id
                                viewModel.selectPage(at: item.pageIndex)
                            },
                            onToggleExpand: {
                                toggleExpand(item)
                            }
                        )
                        .tag(item.id)
                    }
                    .onMove { source, destination in
                        outline.moveItem(from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        deleteItems(at: indexSet)
                    }
                }
                .listStyle(SidebarListStyle())
            }
        }
        .navigationTitle(notebook.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddItem) {
            addItemSheet
        }
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("选择一个页面")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 添加项目表单
    
    private var addItemSheet: some View {
        NavigationView {
            Form {
                Section("标题") {
                    TextField("输入大纲标题", text: $newItemTitle)
                }
                
                Section("页面") {
                    Picker("关联页面", selection: $selectedPageIndex) {
                        ForEach(Array(notebook.pages.enumerated()), id: \.offset) { index, _ in
                            Text("第 \(index + 1) 页").tag(index)
                        }
                    }
                }
            }
            .navigationTitle("添加大纲项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showingAddItem = false
                        newItemTitle = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addItem()
                        showingAddItem = false
                    }
                    .disabled(newItemTitle.isEmpty)
                }
            }
        }
    }
    
    // MARK: - 方法
    
    @State private var selectedPageIndex: Int = 0
    
    private func addItem() {
        let item = OutlineItem(
            title: newItemTitle,
            pageIndex: selectedPageIndex
        )
        outline.addItem(item)
        newItemTitle = ""
    }
    
    private func deleteItems(at indexSet: IndexSet) {
        for index in indexSet {
            outline.removeItem(id: outline.items[index].id)
        }
    }
    
    private func toggleExpand(_ item: OutlineItem) {
        if let index = outline.items.firstIndex(where: { $0.id == item.id }) {
            outline.items[index].isExpanded.toggle()
        }
    }
    
    private func regenerateOutline() {
        outline = NotebookOutline.generate(from: notebook)
    }
}

// MARK: - 大纲项目行

struct OutlineItemRow: View {
    let item: OutlineItem
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleExpand: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // 展开/折叠按钮
            if !item.children.isEmpty {
                Button(action: onToggleExpand) {
                    Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Color.clear
                    .frame(width: 12)
            }
            
            // 图标
            Image(systemName: "doc.text")
                .foregroundColor(isSelected ? .blue : .secondary)
            
            // 标题
            Text(item.title)
                .foregroundColor(isSelected ? .blue : .primary)
            
            Spacer()
            
            // 页面指示
            Text("P\(item.pageIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 预览

struct OutlineModeView_Previews: PreviewProvider {
    static var previews: some View {
        let notebook = Notebook(title: "测试笔记", coverColor: "blue")
        return OutlineModeView(notebook: notebook, viewModel: NotebookViewModel())
    }
}
