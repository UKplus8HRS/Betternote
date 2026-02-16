import SwiftUI
import UIKit

/// 多窗口管理器
/// 支持 iPad 分屏和多窗口
final class MultiWindowManager: ObservableObject {
    
    // MARK: - 场景会话管理
    
    /// 窗口场景信息
    struct WindowSceneInfo: Identifiable {
        let id: UUID
        var title: String
        var notebookId: UUID?
    }
    
    // MARK: - Published 属性
    
    @Published var scenes: [WindowSceneInfo] = []
    
    // MARK: - 窗口管理
    
    /// 创建新窗口
    @MainActor
    func createNewWindow(notebookId: UUID? = nil, title: String = "新窗口") {
        // 在 iPadOS 上，这会触发 SceneDelegate 创建新场景
        NotificationCenter.default.post(
            name: .createNewWindow,
            object: nil,
            userInfo: [
                "notebookId": notebookId as Any,
                "title": title
            ]
        )
    }
    
    /// 关闭窗口
    func closeWindow(id: UUID) {
        scenes.removeAll { $0.id == id }
    }
    
    /// 更新窗口内容
    func updateWindow(id: UUID, notebookId: UUID?, title: String) {
        if let index = scenes.firstIndex(where: { $0.id == id }) {
            scenes[index].notebookId = notebookId
            scenes[index].title = title
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let createNewWindow = Notification.Name("createNewWindow")
}

// MARK: - 分屏模式

/// 分屏模式
enum SplitScreenMode: String, CaseIterable {
    case none = "全屏"
    case half = "分屏"
    case quarter = "四分之一"
    case third = "三分之一"
    case twoThirds = "三分之二"
    
    var icon: String {
        switch self {
        case .none: return "rectangle.fill"
        case .half: return "rectangle.split.2x1"
        case .quarter: return "rectangle.split.2x2"
        case .third: return "rectangle.split.3x1"
        case .twoThirds: return "rectangle.split.3x1"
        }
    }
    
    var sizeFraction: CGFloat {
        switch self {
        case .none: return 1.0
        case .half: return 0.5
        case .quarter: return 0.25
        case .third: return 0.33
        case .twoThirds: return 0.67
        }
    }
}

// MARK: - 分屏控制器

final class SplitScreenController: ObservableObject {
    
    @Published var currentMode: SplitScreenMode = .none
    @Published var isResizing: Bool = false
    
    /// 切换分屏模式
    func toggle(mode: SplitScreenMode) {
        if currentMode == mode {
            currentMode = .none
        } else {
            currentMode = mode
        }
    }
    
    /// 进入分屏
    func enterSplitScreen() {
        currentMode = .half
    }
    
    /// 退出分屏
    func exitSplitScreen() {
        currentMode = .none
    }
}

// MARK: - 分屏工具栏

import SwiftUI

struct SplitScreenToolbar: View {
    @ObservedObject var controller: SplitScreenController
    let onNewWindow: () -> Void
    
    var body: some View {
        Menu {
            ForEach(SplitScreenMode.allCases, id: \.self) { mode in
                Button(action: { controller.toggle(mode: mode) }) {
                    Label(mode.rawValue, systemImage: mode.icon)
                }
            }
            
            Divider()
            
            Button(action: onNewWindow) {
                Label("新建窗口", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: controller.currentMode.icon)
                .font(.system(size: 16))
                .foregroundColor(controller.currentMode != .none ? .blue : .secondary)
        }
    }
}

// MARK: - 多窗口支持 (UIKit)

/// 场景委托配置
/// 在 AppDelegate 或 SceneDelegate 中使用
class SceneDelegateHelper: NSObject {
    
    /// 配置场景
    static func configure(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // 启用多窗口支持
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        
        // 配置场景连接
        if #available(iOS 13.0, *) {
            // 设置场景委托
        }
    }
}

// MARK: - 窗口场景代理

import UIKit

class WindowSceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 创建窗口
        window = UIWindow(windowScene: windowScene)
        
        // 设置根视图控制器
        // window?.rootViewController = ...
        
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // 清理资源
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 激活场景
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // 即将进入后台
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // 即将进入前台
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // 进入后台
    }
}

// MARK: - iPad 分屏支持

/// 分屏视图
/// 用于在 iPad 上同时显示多个内容
struct SplitScreenView: View {
    @Binding var splitMode: SplitScreenMode
    let primaryContent: AnyView
    let secondaryContent: AnyView?
    
    init(splitMode: Binding<SplitScreenMode>, @ViewBuilder primary: () -> AnyView, @ViewBuilder secondary: () -> AnyView?) {
        self._splitMode = splitMode
        self.primaryContent = primary()
        self.secondaryContent = secondary()
    }
    
    var body: some View {
        if splitMode == .none {
            primaryContent
        } else {
            HStack(spacing: 2) {
                primaryContent
                    .frame(maxWidth: splitMode == .half ? .infinity : nil)
                
                if let secondary = secondaryContent {
                    Divider()
                    secondary
                        .frame(maxWidth: splitMode == .half ? .infinity : nil)
                }
            }
        }
    }
}

// MARK: - 手势切换分屏

/// 分屏切换手势
struct SplitScreenGesture: ViewModifier {
    let onToggle: (SplitScreenMode) -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        
                        // 三指滑动切换分屏
                        if abs(horizontal) > abs(vertical) && abs(horizontal) > 100 {
                            if horizontal > 0 {
                                onToggle(.half)
                            } else {
                                onToggle(.none)
                            }
                        }
                    }
            )
    }
}

extension View {
    func splitScreenGesture(onToggle: @escaping (SplitScreenMode) -> Void) -> some View {
        self.modifier(SplitScreenGesture(onToggle: onToggle))
    }
}
