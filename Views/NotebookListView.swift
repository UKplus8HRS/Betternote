import SwiftUI

/// 笔记本列表视图
/// 参考 GoodNotes：网格布局，封面卡片 + 标题
struct NotebookListView: View {
    @EnvironmentObject var viewModel: NotebookViewModel
    @State private var showingCreateSheet = false
    @State private var newNotebookTitle = ""
    @State private var selectedCoverColor = "blue"
    
    /// 封面颜色选项
    private let coverColors = ["blue", "red", "green", "orange", "purple", "yellow", "pink", "gray"]
    
    /// 列数 (根据屏幕宽度自适应)
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                // 添加新笔记本按钮
                Button(action: { showingCreateSheet = true }) {
                    NotebookCoverView(
                        title: "新建笔记本",
                        color: "gray",
                        isAddButton: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 笔记本列表
                ForEach(viewModel.notebooks) { notebook in
                    NotebookCoverView(
                        title: notebook.title,
                        color: notebook.coverColor,
                        isAddButton: false
                    )
                    .onTapGesture {
                        viewModel.selectNotebook(notebook)
                    }
                    .contextMenu {
                        Button("重命名") {
                            // TODO: 实现重命名
                        }
                        Button("删除", role: .destructive) {
                            viewModel.deleteNotebook(notebook)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("笔记本")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateNotebookSheet(
                title: $newNotebookTitle,
                selectedColor: $selectedCoverColor,
                coverColors: coverColors,
                onCreate: {
                    viewModel.createNotebook(title: newNotebookTitle, coverColor: selectedCoverColor)
                    newNotebookTitle = ""
                    selectedCoverColor = "blue"
                    showingCreateSheet = false
                },
                onCancel: {
                    newNotebookTitle = ""
                    selectedCoverColor = "blue"
                    showingCreateSheet = false
                }
            )
        }
    }
}

/// 创建笔记本弹窗
struct CreateNotebookSheet: View {
    @Binding var title: String
    @Binding var selectedColor: String
    let coverColors: [String]
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("笔记本名称") {
                    TextField("输入笔记本名称", text: $title)
                }
                
                Section("封面颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(coverColors, id: \.self) { color in
                            Circle()
                                .fill(Color(coverColorMap[color] ?? .gray))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("新建笔记本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        if title.isEmpty {
                            title = "新笔记本"
                        }
                        onCreate()
                    }
                    .disabled(title.isEmpty && false)
                }
            }
        }
    }
}

/// 封面颜色映射
let coverColorMap: [String: Color] = [
    "blue": .blue,
    "red": .red,
    "green": .green,
    "orange": .orange,
    "purple": .purple,
    "yellow": .yellow,
    "pink": .pink,
    "gray": .gray
]
