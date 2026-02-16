import SwiftUI
import PencilKit

/// 手势和交互管理器
/// 处理画布的手势操作：缩放、旋转、翻页
final class GestureManager: ObservableObject {
    
    // MARK: - Published 属性
    
    /// 当前缩放比例
    @Published var scale: CGFloat = 1.0
    
    /// 当前旋转角度
    @Published var rotation: Angle = .zero
    
    /// 是否正在缩放
    @Published var isScaling: Bool = false
    
    /// 最小缩放
    let minScale: CGFloat = 0.5
    
    /// 最大缩放
    let maxScale: CGFloat = 5.0
    
    // MARK: - 手势处理
    
    /// 处理缩放手势
    /// - Parameters:
    ///   - scale: 新的缩放比例
    ///   - anchor: 缩放锚点
    func handleScale(_ scale: CGFloat, anchor: CGPoint = .zero) {
        let newScale = min(max(self.scale * scale, minScale), maxScale)
        
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
            self.scale = newScale
        }
    }
    
    /// 重置缩放和旋转
    func resetTransform() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = 1.0
            rotation = .zero
        }
    }
    
    /// 双击重置
    func handleDoubleTap() -> Bool {
        if scale > 1.0 {
            resetTransform()
            return true
        }
        return false
    }
}

// MARK: - 翻页方向

enum PageFlipDirection {
    case left
    case right
    case up
    case down
}

/// 页面翻页动画管理器
final class PageFlipManager: ObservableObject {
    
    /// 是否正在翻页动画中
    @Published var isAnimating: Bool = false
    
    /// 翻页方向
    @Published var flipDirection: PageFlipDirection? = nil
    
    /// 翻页动画
    /// - Parameters:
    ///   - direction: 翻页方向
    ///   - completion: 动画完成回调
    func flip(direction: PageFlipDirection, completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        
        isAnimating = true
        flipDirection = direction
        
        // 模拟翻页动画时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
            self.isAnimating = false
            self.flipDirection = nil
        }
    }
}

// MARK: - 缩放变换修饰符

struct ScaleModifier: ViewModifier {
    let scale: CGFloat
    let rotation: Angle
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(rotation)
    }
}

extension View {
    func transform(scale: CGFloat, rotation: Angle) -> some View {
        self.modifier(ScaleModifier(scale: scale, rotation: rotation))
    }
}
