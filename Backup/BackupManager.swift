import Foundation

/// 备份与恢复管理器
final class BackupManager: ObservableObject {
    
    // MARK: - 备份类型
    
    enum BackupType {
        case full       // 完整备份
        case notebook   // 单个笔记本
        case incremental // 增量备份
    }
    
    // MARK: - 备份状态
    
    enum BackupState {
        case idle
        case backingUp
        case restoring
        case completed
        case failed(Error)
    }
    
    // MARK: - Published 属性
    
    @Published var state: BackupState = .idle
    @Published var progress: Double = 0
    @Published var lastBackupDate: Date?
    @Published var backupLocations: [BackupLocation] = []
    
    // MARK: - 备份位置
    
    struct BackupLocation: Identifiable {
        let id = UUID()
        let name: String
        let url: URL
        let date: Date
        let size: Int64
    }
    
    // MARK: - 方法
    
    /// 创建完整备份
    func createFullBackup(notebooks: [Notebook]) async -> URL? {
        await MainActor.run {
            state = .backingUp
            progress = 0
        }
        
        // 收集所有数据
        var backupData: [String: Any] = [
            "version": "1.0",
            "timestamp": Date().timeIntervalSince1970,
            "notebooks": []
        ]
        
        var notebookData: [[String: Any]] = []
        
        for (index, notebook) in notebooks.enumerated() {
            let data: [String: Any] = [
                "id": notebook.id.uuidString,
                "title": notebook.title,
                "coverColor": notebook.coverColor,
                "pages": notebook.pages.map { page in
                    [
                        "id": page.id.uuidString,
                        "drawingData": page.drawingData?.base64EncodedString() ?? "",
                        "template": page.template,
                        "backgroundColor": page.backgroundColor
                    ]
                }
            ]
            notebookData.append(data)
            
            await MainActor.run {
                progress = Double(index + 1) / Double(notebooks.count) * 0.8
            }
        }
        
        backupData["notebooks"] = notebookData
        
        // 序列化
        guard let jsonData = try? JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted) else {
            await MainActor.run {
                state = .failed(NSError(domain: "Backup", code: -1))
            }
            return nil
        }
        
        // 保存到文件
        let fileName = "Betternotes_Backup_\(formatDate(Date())).clawnotesbackup"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try jsonData.write(to: backupURL)
            
            await MainActor.run {
                progress = 1.0
                state = .completed
                lastBackupDate = Date()
            }
            
            return backupURL
        } catch {
            await MainActor.run {
                state = .failed(error)
            }
            return nil
        }
    }
    
    /// 恢复到应用
    func restoreBackup(from url: URL) async -> [Notebook]? {
        await MainActor.run {
            state = .restoring
            progress = 0
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let notebooksArray = json["notebooks"] as? [[String: Any]] else {
                throw NSError(domain: "Backup", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的备份文件"])
            }
            
            var notebooks: [Notebook] = []
            
            for (index, notebookDict) in notebooksArray.enumerated() {
                guard let idString = notebookDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = notebookDict["title"] as? String,
                      let coverColor = notebookDict["coverColor"] as? String else {
                    continue
                }
                
                var notebook = Notebook(id: id, title: title, coverColor: coverColor)
                
                if let pagesArray = notebookDict["pages"] as? [[String: Any]] {
                    notebook.pages = pagesArray.compactMap { pageDict -> NotePage? in
                        guard let pageIdString = pageDict["id"] as? String,
                              let pageId = UUID(uuidString: pageIdString) else {
                            return nil
                        }
                        
                        var page = NotePage(id: pageId)
                        
                        if let drawingBase64 = pageDict["drawingData"] as? String,
                           !drawingBase64.isEmpty,
                           let drawingData = Data(base64Encoded: drawingBase64) {
                            page = NotePage(id: pageId, template: PageTemplate(rawValue: pageDict["template"] as? String ?? "blank") ?? .blank, backgroundColor: pageDict["backgroundColor"] as? String ?? "#FFFFFF")
                            page.updateDrawing(drawingData)
                        }
                        
                        return page
                    }
                }
                
                notebooks.append(notebook)
                
                await MainActor.run {
                    progress = Double(index + 1) / Double(notebooksArray.count)
                }
            }
            
            await MainActor.run {
                state = .completed
            }
            
            return notebooks
            
        } catch {
            await MainActor.run {
                state = .failed(error)
            }
            return nil
        }
    }
    
    /// 导出备份到文件
    func exportBackup(to destination: URL) async throws {
        // 创建备份
        let localStorage = LocalStorageManager()
        let notebooks = localStorage.loadNotebooks()
        
        guard let backupURL = await createFullBackup(notebooks: notebooks) else {
            throw NSError(domain: "Backup", code: -3)
        }
        
        // 移动到目标位置
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        try FileManager.default.moveItem(at: backupURL, to: destination)
    }
    
    /// 从文件导入备份
    func importBackup(from source: URL) async throws -> [Notebook] {
        guard let notebooks = await restoreBackup(from: source) else {
            throw NSError(domain: "Backup", code: -4)
        }
        return notebooks
    }
    
    // MARK: - 私有 func formatDate(_方法
    
    private date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: date)
    }
}
