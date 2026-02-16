import Foundation

/// 笔记页面模型
/// 包含页面的绘制数据、缩略图信息
struct NotePage: Identifiable, Codable {
    var id: UUID
    var drawingData: Data?   // PencilKit 绘制数据序列化
    var thumbnailData: Data? // 页面缩略图缓存
    var createdAt: Date
    var modifiedAt: Date
    
    /// 默认构造函数，创建一个空白页面
    init(id: UUID = UUID()) {
        self.id = id
        self.drawingData = nil
        self.thumbnailData = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// 更新绘制数据
    /// - Parameter data: PencilKit 序列化后的 Data
    mutating func updateDrawing(_ data: Data) {
        self.drawingData = data
        self.modifiedAt = Date()
    }
    
    /// 更新缩略图
    /// - Parameter data: 图片 Data
    mutating func updateThumbnail(_ data: Data) {
        self.thumbnailData = data
    }
}
