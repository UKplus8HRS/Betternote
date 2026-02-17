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
    
    // MARK: - Codable 实现 (自定义持久化)
    
    enum CodingKeys: String, CodingKey {
        case id, template, backgroundColor, createdAt, modifiedAt
        // drawingData 和 thumbnailData 不存入 UserDefault JSON，而是存入文件
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        template = try container.decode(String.self, forKey: .template)
        backgroundColor = try container.decode(String.self, forKey: .backgroundColor)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        
        // 从文件加载大数据
        drawingData = try? Data(contentsOf: NotePage.drawingURL(for: id))
        thumbnailData = try? Data(contentsOf: NotePage.thumbnailURL(for: id))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(template, forKey: .template)
        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        
        // 将大数据写入文件 (副作用)
        if let data = drawingData {
            try? data.write(to: NotePage.drawingURL(for: id))
        } else {
            // 如果数据为空，尝试删除文件
            try? FileManager.default.removeItem(at: NotePage.drawingURL(for: id))
        }
        
        if let thumb = thumbnailData {
            try? thumb.write(to: NotePage.thumbnailURL(for: id))
        } else {
            try? FileManager.default.removeItem(at: NotePage.thumbnailURL(for: id))
        }
    }
    
    // MARK: - 文件路径辅助
    
    private static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private static func drawingURL(for id: UUID) -> URL {
        documentsDirectory().appendingPathComponent("\(id.uuidString)_drawing.dat")
    }
    
    private static func thumbnailURL(for id: UUID) -> URL {
        documentsDirectory().appendingPathComponent("\(id.uuidString)_thumb.dat")
    }
}

// MARK: - CloudKit 支持

import CloudKit

extension NotePage {
    /// 转换为 CloudKit 记录
    /// - Parameter notebookID: 所属笔记本 ID
    func toCKRecord(notebookID: CKRecord.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "NotePage", recordID: recordID)
        
        // 基本属性
        record["template"] = template
        record["backgroundColor"] = backgroundColor
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // 关联父笔记本
        let parentParams = CKReference(recordID: notebookID, action: .deleteSelf)
        record["notebook"] = parentParams
        
        // 处理绘制数据 (CKAsset)
        if let drawingData = drawingData, let asset = createAsset(from: drawingData, suffix: "drawing") {
            record["drawingAsset"] = asset
        }
        
        // 处理缩略图 (CKAsset)
        if let thumbnailData = thumbnailData, let asset = createAsset(from: thumbnailData, suffix: "thumb") {
            record["thumbnailAsset"] = asset
        }
        
        return record
    }
    
    /// 从 CloudKit 记录恢复
    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ".").last,
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        
        self.id = uuid
        self.template = record["template"] as? String ?? PageTemplate.blank.rawValue
        self.backgroundColor = record["backgroundColor"] as? String ?? "#FFFFFF"
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.modifiedAt = record["modifiedAt"] as? Date ?? Date()
        
        // 恢复绘制数据
        if let asset = record["drawingAsset"] as? CKAsset, let fileURL = asset.fileURL {
            self.drawingData = try? Data(contentsOf: fileURL)
        }
        
        // 恢复缩略图
        if let asset = record["thumbnailAsset"] as? CKAsset, let fileURL = asset.fileURL {
            self.thumbnailData = try? Data(contentsOf: fileURL)
        }
    }
    
    /// 创建临时文件 Asset
    private func createAsset(from data: Data, suffix: String) -> CKAsset? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(id.uuidString)_\(suffix).dat"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return CKAsset(fileURL: fileURL)
        } catch {
            print("创建 Asset 失败: \(error)")
            return nil
        }
    }
}
