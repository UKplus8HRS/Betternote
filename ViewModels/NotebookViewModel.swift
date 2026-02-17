import Foundation
import SwiftUI
import Combine
import PencilKit

/// 笔记本 ViewModel
/// 负责笔记本和笔记的业务逻辑
///
/// 功能：
/// - 笔记本 CRUD 操作
/// - 页面管理
/// - 笔记保存 (本地 + iCloud)
/// - 撤销/重做支持
final class NotebookViewModel: ObservableObject {

    // MARK: - Published 属性

    /// 笔记本列表
    @Published var notebooks: [Notebook] = []

    /// 当前选中的笔记本
    @Published var selectedNotebook: Notebook?

    /// 当前选中的页面
    @Published var selectedPage: NotePage?

    /// 当前选中的页面索引
    @Published var selectedPageIndex: Int = 0

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String?

    // MARK: - 私有属性

    /// CloudKit 管理器
    private let cloudKitManager = CloudKitManager()

    /// 本地存储管理器
    private let localStorage = LocalStorageManager()

    /// 撤销/重做栈
    private var undoStack: [PKDrawing] = []
    private var redoStack: [PKDrawing] = []

    /// 最大撤销次数
    private let maxUndoCount = 50

    // MARK: - 初始化

    init() {
        loadNotebooks()
    }

    // MARK: - 笔记本操作

    /// 加载笔记本列表
    func loadNotebooks() {
        isLoading = true

        // 先加载本地数据
        notebooks = localStorage.loadNotebooks()

        // 尝试同步 iCloud
        Task { @MainActor in
            do {
                let cloudNotebooks = try await cloudKitManager.fetchAllNotebooks()
                // 合并数据 (以 iCloud 为准)
                notebooks = mergeNotebooks(local: notebooks, cloud: cloudNotebooks)
                saveNotebooks()
            } catch {
                print("iCloud 同步失败，使用本地数据: \(error)")
            }
            isLoading = false
        }
    }

    /// 创建新笔记本
    /// - Parameters:
    ///   - title: 笔记本标题
    ///   - coverColor: 封面颜色
    func createNotebook(title: String = "新笔记本", coverColor: String = "blue") {
        let notebook = Notebook(title: title, coverColor: coverColor)
        notebooks.insert(notebook, at: 0)
        selectedNotebook = notebook
        saveNotebooks()

        // 异步同步到 iCloud
        Task {
            try? await cloudKitManager.saveNotebook(notebook)
        }
    }

    /// 更新笔记本
    /// - Parameter notebook: 笔记本实例
    func updateNotebook(_ notebook: Notebook) {
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            var updated = notebook
            updated.modifiedAt = Date()
            notebooks[index] = updated

            if selectedNotebook?.id == notebook.id {
                selectedNotebook = updated
            }

            saveNotebooks()

            // 异步同步到 iCloud
            Task {
                try? await cloudKitManager.saveNotebook(updated)
            }
        }
    }

    /// 删除笔记本
    /// - Parameter notebook: 笔记本实例
    func deleteNotebook(_ notebook: Notebook) {
        notebooks.removeAll { $0.id == notebook.id }

        if selectedNotebook?.id == notebook.id {
            selectedNotebook = nil
            selectedPage = nil
        }

        saveNotebooks()

        // 异步同步到 iCloud
        Task {
            try? await cloudKitManager.deleteNotebook(notebook.id)
        }
    }

    /// 选择笔记本
    /// - Parameter notebook: 笔记本实例
    func selectNotebook(_ notebook: Notebook) {
        selectedNotebook = notebook
        selectedPageIndex = 0
        selectedPage = notebook.pages.first
    }

    // MARK: - 页面操作

    /// 添加新页面
    func addPage() {
        guard var notebook = selectedNotebook else { return }

        let newPage = NotePage()
        notebook.pages.append(newPage)

        selectedPageIndex = notebook.pages.count - 1
        selectedPage = newPage

        updateNotebook(notebook)
    }

    /// 删除页面
    /// - Parameter index: 页面索引
    func deletePage(at index: Int) {
        guard var notebook = selectedNotebook,
              notebook.pages.count > 1 else { return }

        notebook.pages.remove(at: index)

        if selectedPageIndex >= notebook.pages.count {
            selectedPageIndex = notebook.pages.count - 1
        }
        selectedPage = notebook.pages[selectedPageIndex]

        updateNotebook(notebook)
    }

    /// 更换页面模板
    /// - Parameters:
    ///   - template: 新模板
    ///   - index: 页面索引
    func changePageTemplate(_ template: PageTemplate, at index: Int? = nil) {
        guard var notebook = selectedNotebook else { return }

        let pageIndex = index ?? selectedPageIndex
        guard pageIndex >= 0 && pageIndex < notebook.pages.count else { return }

        notebook.pages[pageIndex].changeTemplate(template)
        selectedPage = notebook.pages[pageIndex]

        updateNotebook(notebook)
    }

    /// 更换页面背景色
    /// - Parameters:
    ///   - color: 十六进制颜色
    ///   - index: 页面索引
    func changePageBackgroundColor(_ color: String, at index: Int? = nil) {
        guard var notebook = selectedNotebook else { return }

        let pageIndex = index ?? selectedPageIndex
        guard pageIndex >= 0 && pageIndex < notebook.pages.count else { return }

        notebook.pages[pageIndex].changeBackgroundColor(color)
        selectedPage = notebook.pages[pageIndex]

        updateNotebook(notebook)
    }

    /// 选择页面
    /// - Parameter index: 页面索引
    func selectPage(at index: Int) {
        guard let notebook = selectedNotebook,
              index >= 0 && index < notebook.pages.count else { return }

        selectedPageIndex = index
        selectedPage = notebook.pages[index]
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// 更新页面绘制数据
    /// - Parameters:
    ///   - drawing: PencilKit 绘图数据
    ///   - pageIndex: 页面索引
    func updatePageDrawing(_ drawing: PKDrawing, at pageIndex: Int? = nil) {
        guard var notebook = selectedNotebook else { return }

        let index = pageIndex ?? selectedPageIndex
        guard index >= 0 && index < notebook.pages.count else { return }

        // 保存到撤销栈
        if let currentDrawing = notebook.pages[index].drawingData,
           let drawingObj = try? PKDrawing(data: currentDrawing) {
            undoStack.append(drawingObj)
            if undoStack.count > maxUndoCount {
                undoStack.removeFirst()
            }
        }
        redoStack.removeAll()

        // 更新绘制数据
        let drawingData = drawing.dataRepresentation()
        notebook.pages[index].updateDrawing(drawingData)

        // 更新缩略图
        if let thumbnail = drawing.image(from: drawing.bounds, scale: 1.0).pngData() {
            notebook.pages[index].updateThumbnail(thumbnail)
        }
        
        // 更新笔记本修改时间
        notebook.modifiedAt = Date()

        selectedNotebook = notebook
        notebooks = notebooks.map { $0.id == notebook.id ? notebook : $0 }
        saveNotebooks()
        
        // 异步同步到 iCloud
        Task {
            try? await cloudKitManager.saveNotebook(notebook)
        }
    }

    // MARK: - 撤销/重做

    /// 撤销
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// 重做
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// 执行撤销
    func undo(drawing: PKDrawing) -> PKDrawing? {
        guard let previousDrawing = undoStack.popLast() else { return nil }

        redoStack.append(drawing)

        return previousDrawing
    }

    /// 执行重做
    func redo(drawing: PKDrawing) -> PKDrawing? {
        guard let nextDrawing = redoStack.popLast() else { return nil }

        undoStack.append(drawing)

        return nextDrawing
    }

    // MARK: - 私有方法

    /// 保存到本地存储
    private func saveNotebooks() {
        localStorage.saveNotebooks(notebooks)
    }

    /// 合并本地和云端数据
    /// - Parameters:
    ///   - local: 本地笔记本
    ///   - cloud: 云端笔记本
    /// - Returns: 合并后的笔记本列表
    private func mergeNotebooks(local: [Notebook], cloud: [Notebook]) -> [Notebook] {
        var merged: [Notebook] = []

        for cloudNotebook in cloud {
            if let localIndex = local.firstIndex(where: { $0.id == cloudNotebook.id }) {
                // 两者都存在，以最新修改时间为准
                let localNotebook = local[localIndex]
                merged.append(cloudNotebook.modifiedAt > localNotebook.modifiedAt ? cloudNotebook : localNotebook)
            } else {
                // 仅云端存在
                merged.append(cloudNotebook)
            }
        }

        // 添加仅本地存在的
        for localNotebook in local {
            if !merged.contains(where: { $0.id == localNotebook.id }) {
                merged.append(localNotebook)
            }
        }

        return merged.sorted { $0.modifiedAt > $1.modifiedAt }
    }
}

// MARK: - 本地存储管理器

/// 本地存储管理器
/// 使用 UserDefaults 存储笔记本数据 (MVP 阶段)
/// 未来可迁移到 Core Data 或 SQLite
final class LocalStorageManager {

    private let notebooksKey = "com.clawnotes.notebooks"

    /// 加载笔记本列表
    func loadNotebooks() -> [Notebook] {
        guard let data = UserDefaults.standard.data(forKey: notebooksKey) else {
            return []
        }

        do {
            let notebooks = try JSONDecoder().decode([Notebook].self, from: data)
            return notebooks
        } catch {
            print("加载笔记本失败: \(error)")
            return []
        }
    }

    /// 保存笔记本列表
    func saveNotebooks(_ notebooks: [Notebook]) {
        do {
            let data = try JSONEncoder().encode(notebooks)
            UserDefaults.standard.set(data, forKey: notebooksKey)
        } catch {
            print("保存笔记本失败: \(error)")
        }
    }
}
