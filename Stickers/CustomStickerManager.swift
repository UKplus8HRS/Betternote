import Foundation
import PencilKit
import UIKit

/// 自定义贴纸管理器
/// 让用户把画的图案变成贴纸
final class CustomStickerManager: ObservableObject {
    
    // MARK: - 自定义贴纸
    
    struct CustomSticker: Identifiable, Codable {
        var id: UUID
        var name: String
        var imageData: Data      // 贴纸图片
        var thumbnailData: Data? // 缩略图
        var category: String
        var createdAt: Date
        
        init(id: UUID = UUID(), name: String, imageData: Data, category: String = "自定义") {
            self.id = id
            self.name = name
            self.imageData = imageData
            self.thumbnailData = nil
            self.category = category
            self.createdAt = Date()
        }
    }
    
    // MARK: - Published 属性
    
    @Published var customStickers: [CustomSticker] = []
    
    // MARK: - 方法
    
    /// 从绘图创建贴纸
    func createSticker(from drawing: PKDrawing, name: String, category: String = "自定义") -> CustomSticker? {
        // 生成高分辨率图片
        let image = drawing.image(from: drawing.bounds, scale: 3.0)
        
        guard let imageData = image.pngData() else {
            return nil
        }
        
        // 生成缩略图
        let thumbnail = drawing.image(from: drawing.bounds, scale: 0.5)
        let thumbnailData = thumbnail.pngData()
        
        var sticker = CustomSticker(name: name, imageData: imageData, category: category)
        sticker.thumbnailData = thumbnailData
        
        return sticker
    }
    
    /// 保存自定义贴纸
    func saveSticker(_ sticker: CustomSticker) {
        customStickers.append(sticker)
        saveToDisk()
    }
    
    /// 删除贴纸
    func deleteSticker(_ sticker: CustomSticker) {
        customStickers.removeAll { $0.id == sticker.id }
        saveToDisk()
    }
    
    /// 重命名贴纸
    func renameSticker(_ sticker: CustomSticker, to newName: String) {
        if let index = customStickers.firstIndex(where: { $0.id == sticker.id }) {
            customStickers[index].name = newName
            saveToDisk()
        }
    }
    
    /// 移动贴纸到分类
    func moveSticker(_ sticker: CustomSticker, to category: String) {
        if let index = customStickers.firstIndex(where: { $0.id == sticker.id }) {
            customStickers[index].category = category
            saveToDisk()
        }
    }
    
    /// 获取分类列表
    func categories() -> [String] {
        let allCategories = customStickers.map { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    /// 获取分类下的贴纸
    func stickers(in category: String) -> [CustomSticker] {
        return customStickers.filter { $0.category == category }
    }
    
    // MARK: - 存储
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(customStickers) {
            UserDefaults.standard.set(data, forKey: "customStickers")
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "customStickers"),
           let stickers = try? JSONDecoder().decode([CustomSticker].self, from: data) {
            customStickers = stickers
        }
    }
    
    // 初始化时加载
    init() {
        loadFromDisk()
    }
}
