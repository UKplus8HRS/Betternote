import SwiftUI
import PencilKit

/// 贴纸模型
struct Sticker: Identifiable, Codable {
    var id: UUID
    var name: String
    var imageData: Data?
    var emoji: String?
    var category: StickerCategory
    var isCustom: Bool
    
    enum StickerCategory: String, Codable, CaseIterable {
        case emoji = "表情"
        case shape = "图形"
        case arrow = "箭头"
        case icon = "图标"
        case custom = "自定义"
    }
    
    init(id: UUID = UUID(), name: String, imageData: Data? = nil, emoji: String? = nil, category: StickerCategory, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.emoji = emoji
        self.category = category
        self.isCustom = isCustom
    }
}

/// 贴纸包
struct StickerPack: Identifiable, Codable {
    var id: UUID
    var name: String
    var stickers: [Sticker]
    var iconEmoji: String
    
    init(id: UUID = UUID(), name: String, iconEmoji: String, stickers: [Sticker] = []) {
        self.id = id
        self.name = name
        self.stickers = stickers
        self.iconEmoji = iconEmoji
    }
}

/// 贴纸管理器
final class StickerManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var stickerPacks: [StickerPack] = []
    @Published var customStickers: [Sticker] = []
    
    // MARK: - 初始化
    
    init() {
        loadDefaultStickerPacks()
    }
    
    // MARK: - 默认贴纸包
    
    private func loadDefaultStickerPacks() {
        // Emoji 贴纸包
        let emojiStickers = StickerPack(
            name: "表情",
            iconEmoji: "😀",
            stickers: [
                Sticker(name: "笑脸", emoji: "😀", category: .emoji),
                Sticker(name: "开心", emoji: "😄", category: .emoji),
                Sticker(name: "大笑", emoji: "😃", category: .emoji),
                Sticker(name: "眨眼", emoji: "😉", category: .emoji),
                Sticker(name: "爱心", emoji: "❤️", category: .emoji),
                Sticker(name: "星星", emoji: "⭐️", category: .emoji),
                Sticker(name: "火焰", emoji: "🔥", category: .emoji),
                Sticker(name: "闪电", emoji: "⚡️", category: .emoji),
            ]
        )
        
        // 图形贴纸包
        let shapeStickers = StickerPack(
            name: "图形",
            iconEmoji: "🔷",
            stickers: [
                Sticker(name: "圆形", emoji: "⭕️", category: .shape),
                Sticker(name: "方形", emoji: "⬜", category: .shape),
                Sticker(name: "三角形", emoji: "🔺", category: .shape),
                Sticker(name: "星形", emoji: "⭐️", category: .shape),
                Sticker(name: "心形", emoji: "❤️", category: .shape),
                Sticker(name: "菱形", emoji: "🔶", category: .shape),
            ]
        )
        
        // 箭头贴纸包
        let arrowStickers = StickerPack(
            name: "箭头",
            iconEmoji: "➡️",
            stickers: [
                Sticker(name: "右箭头", emoji: "➡️", category: .arrow),
                Sticker(name: "左箭头", emoji: "⬅️", category: .arrow),
                Sticker(name: "上箭头", emoji: "⬆️", category: .arrow),
                Sticker(name: "下箭头", emoji: "⬇️", category: .arrow),
                Sticker(name: "双箭头", emoji: "↔️", category: .arrow),
                Sticker name: "循环", emoji: "🔄", category: .arrow),
            ]
        )
        
        // 符号贴纸包
        let symbolStickers = StickerPack(
            name: "符号",
            iconEmoji: "✓",
            stickers: [
                Sticker(name: "勾", emoji: "✓", category: .icon),
                Sticker(name: "叉", emoji: "✗", category: .icon),
                Sticker(name: "问号", emoji: "❓", category: .icon),
                Sticker(name: "感叹号", emoji: "❗️", category: .icon),
                Sticker(name: "对勾", emoji: "✅", category: .icon),
                Sticker(name: "叉号", emoji: "❌", category: .icon),
            ]
        )
        
        stickerPacks = [emojiStickers, shapeStickers, arrowStickers, symbolStickers]
    }
    
    // MARK: - 方法
    
    /// 添加自定义贴纸
    func addCustomSticker(_ sticker: Sticker) {
        customStickers.append(sticker)
        saveCustomStickers()
    }
    
    /// 删除自定义贴纸
    func deleteCustomSticker(_ sticker: Sticker) {
        customStickers.removeAll { $0.id == sticker.id }
        saveCustomStickers()
    }
    
    /// 保存自定义贴纸
    private func saveCustomStickers() {
        if let data = try? JSONEncoder().encode(customStickers) {
            UserDefaults.standard.set(data, forKey: "customStickers")
        }
    }
    
    /// 加载自定义贴纸
    private func loadCustomStickers() {
        if let data = UserDefaults.standard.data(forKey: "customStickers"),
           let stickers = try? JSONDecoder().decode([Sticker].self, from: data) {
            customStickers = stickers
        }
    }
}

// MARK: - 贴纸选择器视图

struct StickerPickerView: View {
    @ObservedObject var stickerManager: StickerManager
    @Binding var selectedSticker: Sticker?
    var onStickerSelected: (Sticker) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(stickerManager.stickerPacks) { pack in
                        VStack(spacing: 4) {
                            Text(pack.iconEmoji)
                                .font(.title2)
                            Text(pack.name)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            // 贴纸网格
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60))
                ], spacing: 16) {
                    ForEach(stickerManager.stickerPacks.flatMap { $0.stickers }) { sticker in
                        StickerCell(sticker: sticker, isSelected: selectedSticker?.id == sticker.id)
                            .onTapGesture {
                                selectedSticker = sticker
                                onStickerSelected(sticker)
                            }
                    }
                }
                .padding()
            }
        }
    }
}

struct StickerCell: View {
    let sticker: Sticker
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                .frame(width: 50, height: 50)
            
            Text(sticker.emoji ?? "❓")
                .font(.system(size: 28))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
