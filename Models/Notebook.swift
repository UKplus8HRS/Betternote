import Foundation
import CloudKit

/// 笔记本模型
/// 包含笔记本的基本信息、页面列表、云同步支持
struct Notebook: Identifiable, Codable {
    var id: UUID
    var title: String
    var coverColor: String
    var pages: [NotePage]
    var createdAt: Date
    var modifiedAt: Date
    
    /// 默认构造函数，创建一个新笔记本
    /// - Parameters:
    ///   - title: 笔记本标题，默认"新笔记本"
    ///   - coverColor: 封面颜色，默认蓝色
    init(id: UUID = UUID(), title: String = "新笔记本", coverColor: String = "blue") {
        self.id = id
        self.title = title
        self.coverColor = coverColor
        self.pages = [NotePage()]
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - CloudKit 支持
    
    /// CloudKit 记录类型
    static let recordType = "Notebook"
    
    /// 将 Notebook 转换为 CloudKit 记录
    /// - Returns: CKRecord 实例
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Notebook.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["coverColor"] = coverColor
        record["modifiedAt"] = modifiedAt
        // pages 数据较大，建议单独存储或使用 CKAsset
        return record
    }
    
    /// 从 CloudKit 记录创建 Notebook
    /// - Parameter record: CKRecord 实例
    /// - Returns: Notebook 实例，转换失败返回 nil
    static func from(record: CKRecord) -> Notebook? {
        guard let idString = record.recordID.recordName as String?,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String,
              let coverColor = record["coverColor"] as? String,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        var notebook = Notebook(id: id, title: title, coverColor: coverColor)
        notebook.modifiedAt = modifiedAt
        return notebook
    }
}
