import SwiftUI

/// 笔记本封面视图
/// 参考 GoodNotes 风格
struct NotebookCoverView: View {
    let title: String
    let color: String
    let isAddButton: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 封面主体
            ZStack {
                // 背景色
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(coverColorMap[color] ?? .blue))
                    .overlay(
                        // 纸张纹理效果
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                if isAddButton {
                    // 添加按钮图标
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    // 笔记本内页效果
                    VStack(spacing: 0) {
                        // 顶部装订线
                        HStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: 15, height: 2)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // 模拟横线
                        VStack(spacing: 6) {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .frame(height: 180)
            
            // 标题
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 4)
        }
        .frame(width: 150)
    }
}

// MARK: - 预览

struct NotebookCoverView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            NotebookCoverView(title: "数学笔记", color: "blue", isAddButton: false)
            NotebookCoverView(title: "新建笔记本", color: "gray", isAddButton: true)
        }
        .padding()
    }
}
