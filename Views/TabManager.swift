import SwiftUI

/// 标签页模型
/// 用于多窗口/标签页功能
struct NoteTab: Identifiable, Codable {
    var id: UUID
    var notebookId: UUID?
    var notebookTitle: String
    var pageIndex: Int
    var lastOpenedAt: Date
    
    init(id: UUID = UUID(), notebookId: UUID? = nil, notebookTitle: String = "新笔记", pageIndex: Int = 0) {
        self.id = id
        self.notebookId = notebookId
        self.notebookTitle = notebookTitle
        self.pageIndex = pageIndex
        self.lastOpenedAt = Date()
    }
}

/// 标签页管理器
final class TabManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var tabs: [NoteTab] = []
    @Published var activeTabId: UUID?
    
    // MARK: - 限制
    
    /// 最大标签页数量
    let maxTabs = 10
    
    // MARK: - 方法
    
    /// 创建新标签页
    func createTab(notebookId: UUID? = nil, notebookTitle: String = "新笔记") -> NoteTab {
        // 如果达到最大数量，关闭最早的标签页
        if tabs.count >= maxTabs {
            closeTab(at: 0)
        }
        
        let tab = NoteTab(notebookId: notebookId, notebookTitle: notebookTitle)
        tabs.append(tab)
        activeTabId = tab.id
        
        return tab
    }
    
    /// 关闭标签页
    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        closeTab(at: index)
    }
    
    /// 根据索引关闭标签页
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        
        let closedTab = tabs.remove(at: index)
        
        // 如果关闭的是当前激活的标签页，切换到相邻的
        if activeTabId == closedTab.id {
            if tabs.isEmpty {
                activeTabId = nil
            } else if index >= tabs.count {
                activeTabId = tabs.last?.id
            } else {
                activeTabId = tabs[index].id
            }
        }
    }
    
    /// 切换到指定标签页
    func switchToTab(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        activeTabId = id
        
        // 更新最后打开时间
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            tabs[index].lastOpenedAt = Date()
        }
    }
    
    /// 移动标签页
    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
    }
    
    /// 重新排序标签页
    func reorderTabs() {
        // 按最后打开时间排序
        tabs.sort { $0.lastOpenedAt > $1.lastOpenedAt }
    }
    
    /// 更新标签页内容
    func updateTab(id: UUID, notebookId: UUID?, notebookTitle: String, pageIndex: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        tabs[index].notebookId = notebookId
        tabs[index].notebookTitle = notebookTitle
        tabs[index].pageIndex = pageIndex
        tabs[index].lastOpenedAt = Date()
    }
    
    /// 关闭所有标签页
    func closeAllTabs() {
        tabs.removeAll()
        activeTabId = nil
    }
    
    /// 关闭其他标签页
    func closeOtherTabs(keepId: UUID) {
        tabs = tabs.filter { $0.id == keepId }
        activeTabId = keepId
    }
}

// MARK: - 标签栏视图

import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    @Binding var showingNotebookList: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // 标签页列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTabId,
                            onTap: {
                                tabManager.switchToTab(id: tab.id)
                            },
                            onClose: {
                                tabManager.closeTab(id: tab.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // 新建标签按钮
            if tabManager.tabs.count < tabManager.maxTabs {
                Button(action: {
                    let _ = tabManager.createTab()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
                .frame(height: 24)
            
            // 笔记本列表按钮
            Button(action: {
                showingNotebookList = true
            }) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct TabItemView: View {
    let tab: NoteTab
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // 标签图标
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundColor(isActive ? .blue : .secondary)
            
            // 标签标题
            Text(tab.notebookTitle)
                .font(.system(size: 13))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 100)
            
            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovered || isActive ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 标签页内容视图

struct TabContentView: View {
    @ObservedObject var tabManager: TabManager
    @EnvironmentObject var notebookVM: NotebookViewModel
    
    var body: some View {
        if let activeTabId = tabManager.activeTabId,
           let tab = tabManager.tabs.first(where: { $0.id == activeTabId }) {
            
            if let notebookId = tab.notebookId,
               let notebook = notebookVM.notebooks.first(where: { $0.id == notebookId }) {
                NotebookDetailView(notebook: notebook)
            } else {
                // 新建笔记或空状态
                VStack(spacing: 20) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("选择或创建一个笔记本")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Button("打开笔记本") {
                        // 打开笔记本选择
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            // 没有标签页
            VStack(spacing: 20) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("点击 + 创建新标签页")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
}
