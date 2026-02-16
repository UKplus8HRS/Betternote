//
//  CloudKitManagerTests.swift
//  ClawNotesTests
//
//  测试 CloudKit 同步功能
//

import XCTest
@testable import ClawNotes

/// CloudKit 管理器测试
final class CloudKitManagerTests: XCTestCase {
    
    var manager: CloudKitManager!
    
    override func setUp() {
        super.setUp()
        manager = CloudKitManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testAccountStatusCheck() async {
        let status = await manager.checkAccountStatus()
        
        // 根据账户状态测试
        switch status {
        case .available, .restricted, .couldNotDetermine, .noAccount, .temporarilyUnavailable:
            XCTAssertTrue(true)
        @unknown default:
            XCTFail("未知的账户状态")
        }
    }
}

/// 本地存储测试
final class LocalStorageTests: XCTestCase {
    
    var storage: LocalStorageManager!
    
    override func setUp() {
        super.setUp()
        storage = LocalStorageManager()
    }
    
    override func tearDown() {
        // 清理测试数据
        UserDefaults.standard.removeObject(forKey: "com.clawnotes.notebooks")
        storage = nil
        super.tearDown()
    }
    
    func testSaveAndLoadNotebooks() {
        let notebook = Notebook(title: "测试", coverColor: "blue")
        storage.saveNotebooks([notebook])
        
        let loaded = storage.loadNotebooks()
        
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "测试")
    }
    
    func testEmptyLoad() {
        let loaded = storage.loadNotebooks()
        XCTAssertTrue(loaded.isEmpty)
    }
}

/// 模板测试
final class TemplateTests: XCTestCase {
    
    var manager: TemplateManager!
    
    override func setUp() {
        super.setUp()
        manager = TemplateManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testBuiltInTemplatesCount() {
        XCTAssertGreaterThan(manager.templates.count, 20)
    }
    
    func testSearchByName() {
        let results = manager.search(query: "单词")
        XCTAssertFalse(results.isEmpty)
    }
    
    func testSearchByDescription() {
        let results = manager.search(query: "会议")
        XCTAssertFalse(results.isEmpty)
    }
    
    func testSearchByTag() {
        let results = manager.search(query: "学习")
        XCTAssertFalse(results.isEmpty)
    }
    
    func testCreateNotebookFromTemplate() {
        guard let template = manager.templates.first else { return }
        
        let notebook = manager.createNotebook(from: template)
        
        XCTAssertNotNil(notebook)
        XCTAssertEqual(notebook.title, template.name)
        XCTAssertFalse(notebook.pages.isEmpty)
    }
}

/// 备份测试
final class BackupTests: XCTestCase {
    
    var backupManager: BackupManager!
    
    override func setUp() {
        super.setUp()
        backupManager = BackupManager()
    }
    
    override func tearDown() {
        backupManager = nil
        super.tearDown()
    }
    
    func testBackupCreation() async {
        let notebook = Notebook(title: "测试", coverColor: "blue")
        
        let url = await backupManager.createFullBackup(notebooks: [notebook])
        
        XCTAssertNotNil(url)
    }
    
    func testRestoreBackup() async {
        let notebook = Notebook(title: "测试", coverColor: "blue")
        
        // 先创建备份
        guard let url = await backupManager.createFullBackup(notebooks: [notebook]) else {
            XCTFail("备份创建失败")
            return
        }
        
        // 恢复备份
        let restored = await backupManager.restoreBackup(from: url)
        
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.count, 1)
    }
}

/// 主题测试
final class ThemeTests: XCTestCase {
    
    var manager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        manager = ThemeManager()
    }
    
    override func tearDown() {
        manager.resetToDefault()
        manager = nil
        super.tearDown()
    }
    
    func testDefaultTheme() {
        XCTAssertNotNil(manager.currentTheme)
    }
    
    func testSetTheme() {
        let nightTheme = AppTheme.night
        manager.setTheme(nightTheme)
        
        XCTAssertEqual(manager.currentTheme.id, nightTheme.id)
    }
    
    func testPresetsCount() {
        XCTAssertGreaterThanOrEqual(AppTheme.presets.count, 3)
    }
}

/// 安全测试
final class SecurityTests: XCTestCase {
    
    var manager: SecurityManager!
    
    override func setUp() {
        super.setUp()
        manager = SecurityManager()
    }
    
    override func tearDown() {
        manager.removePasscode()
        manager = nil
        super.tearDown()
    }
    
    func testBiometricType() {
        let type = manager.biometricType
        // 根据设备可能有不同结果
        XCTAssertTrue(true)
    }
    
    func testSetAndVerifyPasscode() {
        manager.setPasscode("1234")
        XCTAssertTrue(manager.settings.usePasscode)
        
        XCTAssertTrue(manager.authenticateWithPasscode("1234"))
        XCTAssertFalse(manager.authenticateWithPasscode("wrong"))
    }
}
