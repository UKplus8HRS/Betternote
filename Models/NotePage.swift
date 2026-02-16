import Foundation

/// 笔记页面模型
/// 包含页面的绘制数据、缩略图信息、模板类型
struct NotePage: Identifiable, Codable {
    var id: UUID
    var drawingData: Data?   // PencilKit 绘制数据序列化
    var thumbnailData: Data? // 页面缩略图缓存
    var template: String     // 页面模板类型
    var backgroundColor: String // 背景色
    var createdAt: Date
    var modifiedAt: Date
    
    /// 默认构造函数，创建一个空白页面
    /// - Parameter template: 页面模板类型
    init(id: UUID = UUID(), template: PageTemplate = .blank, backgroundColor: String = "#FFFFFF") {
        self.id = id
        self.drawingData = nil
        self.thumbnailData = nil
        self.template = template.rawValue
        self.backgroundColor = backgroundColor
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// 获取模板枚举
    var templateType: PageTemplate {
        PageTemplate(rawValue: template) ?? .blank
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
    
    /// 更换模板
    /// - Parameter newTemplate: 新模板
    mutating func changeTemplate(_ newTemplate: PageTemplate) {
        self.template = newTemplate.rawValue
        self.modifiedAt = Date()
    }
    
    /// 更换背景色
    /// - Parameter color: 十六进制颜色
    mutating func changeBackgroundColor(_ color: String) {
        self.backgroundColor = color
        self.modifiedAt = Date()
    }
}
