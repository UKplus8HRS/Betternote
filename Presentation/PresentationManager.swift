import SwiftUI
import PencilKit

/// 演示模式管理器
/// 用于演示笔记内容
final class PresentationManager: ObservableObject {
    
    // MARK: - 演示状态
    
    enum PresentationState {
        case idle
        case presenting
        case paused
    }
    
    // MARK: - Published 属性
    
    @Published var state: PresentationState = .idle
    @Published var currentPageIndex: Int = 0
    @Published var showControls: Bool = true
    @Published var isFullScreen: Bool = false
    
    // MARK: - 演示控制
    
    /// 开始演示
    func startPresentation(from pageIndex: Int = 0) {
        currentPageIndex = pageIndex
        state = .presenting
        isFullScreen = true
        
        // 隐藏状态栏
        hideStatusBar()
    }
    
    /// 停止演示
    func stopPresentation() {
        state = .idle
        isFullScreen = false
        
        // 显示状态栏
        showStatusBar()
    }
    
    /// 暂停演示
    func pause() {
        state = .paused
    }
    
    /// 继续演示
    func resume() {
        state = .presenting
    }
    
    /// 上一页
    func previousPage(totalPages: Int) -> Bool {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            return true
        }
        return false
    }
    
    /// 下一页
    func nextPage(totalPages: Int) -> Bool {
        if currentPageIndex < totalPages - 1 {
            currentPageIndex += 1
            return true
        }
        return false
    }
    
    /// 跳转到指定页
    func goToPage(_ index: Int, totalPages: Int) {
        if index >= 0 && index < totalPages {
            currentPageIndex = index
        }
    }
    
    // MARK: - 状态栏控制
    
    private func hideStatusBar() {
        // 通过 NotificationCenter 通知 UIKit
        NotificationCenter.default.post(name: .hideStatusBar, object: nil)
    }
    
    private func showStatusBar() {
        NotificationCenter.default.post(name: .showStatusBar, object: nil)
    }
}

// MARK: - 通知

extension Notification.Name {
    static let hideStatusBar = Notification.Name("hideStatusBar")
    static let showStatusBar = Notification.Name("showStatusBar")
}

// MARK: - 演示视图

struct PresentationView: View {
    @ObservedObject var presentationManager: PresentationManager
    let notebook: Notebook
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPagePicker = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            // 当前页面
            if currentPageIndex < notebook.pages.count {
                let page = notebook.pages[currentPageIndex]
                NoteCanvasView(page: page, pageIndex: currentPageIndex)
                    .ignoresSafeArea()
            }
            
            // 控制层
            if presentationManager.showControls {
                VStack {
                    // 顶部栏
                    topBar
                    
                    Spacer()
                    
                    // 底部栏
                    bottomBar
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: presentationManager.isFullScreen)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    handleSwipe(value)
                }
        )
        .onTapGesture {
            withAnimation {
                presentationManager.showControls.toggle()
            }
        }
        .sheet(isPresented: $showingPagePicker) {
            PagePickerSheet(
                currentPage: presentationManager.currentPageIndex,
                totalPages: notebook.pages.count,
                onSelect: { index in
                    presentationManager.goToPage(index, totalPages: notebook.pages.count)
                }
            )
        }
    }
    
    // MARK: - 顶部栏
    
    private var topBar: some View {
        HStack {
            Button(action: { presentationManager.stopPresentation() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            
            Spacer()
            
            Text(notebook.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.5)))
            
            Spacer()
            
            Button(action: { showingPagePicker = true }) {
                Text("\(currentPageIndex + 1)/\(notebook.pages.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - 底部栏
    
    private var bottomBar: some View {
        HStack(spacing: 40) {
            // 上一页
            Button(action: {
                _ = presentationManager.previousPage(totalPages: notebook.pages.count)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .foregroundColor(currentPageIndex > 0 ? .white : .gray)
            }
            .disabled(currentPageIndex == 0)
            
            // 播放/暂停
            Button(action: {
                if presentationManager.state == .presenting {
                    presentationManager.pause()
                } else {
                    presentationManager.resume()
                }
            }) {
                Image(systemName: presentationManager.state == .presenting ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            
            // 下一页
            Button(action: {
                _ = presentationManager.nextPage(totalPages: notebook.pages.count)
            }) {
                Image(systemName: "chevron.right")
                    .font(.title)
                    .foregroundColor(currentPageIndex < notebook.pages.count - 1 ? .white : .gray)
            }
            .disabled(currentPageIndex >= notebook.pages.count - 1)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - 手势处理
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        
        if abs(horizontal) > abs(vertical) {
            // 水平滑动
            if horizontal < -50 {
                // 向左滑 - 下一页
                _ = presentationManager.nextPage(totalPages: notebook.pages.count)
            } else if horizontal > 50 {
                // 向右滑 - 上一页
                _ = presentationManager.previousPage(totalPages: notebook.pages.count)
            }
        }
    }
    
    private var currentPageIndex: Int {
        presentationManager.currentPageIndex
    }
}

// MARK: - 页面选择器

struct PagePickerSheet: View {
    let currentPage: Int
    let totalPages: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Button(action: {
                            onSelect(index)
                            dismiss()
                        }) {
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .frame(width: 70, height: 90)
                                        .shadow(color: .black.opacity(0.1), radius: 2)
                                    
                                    if currentPage == index {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 2)
                                    }
                                }
                                
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(currentPage == index ? .blue : .primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择页面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
