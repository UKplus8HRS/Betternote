//
//  ClawNotesTests.swift
//  ClawNotes
//
//  Created by ClawNotes Team.
//  Copyright © 2026. All rights reserved.
//

import XCTest
@testable import ClawNotes

/// 笔记本模型测试
final class NotebookTests: XCTestCase {
    
    var notebook: Notebook!
    
    override func setUp() {
        super.setUp()
        notebook = Notebook(title: "测试笔记本", coverColor: "blue")
    }
    
    override func tearDown() {
        notebook = nil
        super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testNotebookInitialization() {
        XCTAssertNotNil(notebook.id)
        XCTAssertEqual(notebook.title, "测试笔记本")
        XCTAssertEqual(notebook.coverColor, "blue")
        XCTAssertEqual(notebook.pages.count, 1) // 默认有一个空白页
    }
    
    // MARK: - 页面测试
    
    func testAddPage() {
        let initialCount = notebook.pages.count
        notebook.pages.append(NotePage())
        XCTAssertEqual(notebook.pages.count, initialCount + 1)
    }
    
    func testRemovePage() {
        notebook.pages.append(NotePage())
        notebook.pages.append(NotePage())
        
        let initialCount = notebook.pages.count
        notebook.pages.removeLast()
        
        XCTAssertEqual(notebook.pages.count, initialCount - 1)
    }
    
    // MARK: - 日期测试
    
    func testCreatedDate() {
        XCTAssertNotNil(notebook.createdAt)
        XCTAssertLessThan(notebook.createdAt, Date())
    }
    
    func testModifiedDate() {
        let originalDate = notebook.modifiedAt
        notebook.modifiedAt = Date()
        
        XCTAssertNotEqual(originalDate, notebook.modifiedAt)
    }
}

/// 页面模型测试
final class NotePageTests: XCTestCase {
    
    var page: NotePage!
    
    override func setUp() {
        super.setUp()
        page = NotePage()
    }
    
    override func tearDown() {
        page = nil
        super.tearDown()
    }
    
    func testPageInitialization() {
        XCTAssertNotNil(page.id)
        XCTAssertNil(page.drawingData)
        XCTAssertNil(page.thumbnailData)
        XCTAssertEqual(page.template, PageTemplate.blank.rawValue)
    }
    
    func testUpdateDrawing() {
        let testData = "test drawing data".data(using: .utf8)!
        page.updateDrawing(testData)
        
        XCTAssertNotNil(page.drawingData)
        XCTAssertEqual(page.drawingData, testData)
    }
    
    func testChangeTemplate() {
        page.changeTemplate(.lined)
        XCTAssertEqual(page.template, PageTemplate.lined.rawValue)
    }
}

/// 模板测试
final class TemplateTests: XCTestCase {
    
    var templateManager: TemplateManager!
    
    override func setUp() {
        super.setUp()
        templateManager = TemplateManager()
    }
    
    override func tearDown() {
        templateManager = nil
        super.tearDown()
    }
    
    func testLoadBuiltInTemplates() {
        XCTAssertFalse(templateManager.templates.isEmpty)
    }
    
    func testTemplatesCount() {
        // 至少有 15 个内置模板
        XCTAssertGreaterThanOrEqual(templateManager.templates.count, 15)
    }
    
    func testSearchTemplates() {
        let results = templateManager.search(query: "英语")
        XCTAssertFalse(results.isEmpty)
    }
    
    func testCreateNotebookFromTemplate() {
        guard let template = templateManager.templates.first else { return }
        
        let notebook = templateManager.createNotebook(from: template)
        
        XCTAssertNotNil(notebook)
        XCTAssertEqual(notebook.title, template.name)
    }
}

/// 文件夹测试
final class FolderTests: XCTestCase {
    
    var folder: Folder!
    
    override func setUp() {
        super.setUp()
        folder = Folder(name: "测试文件夹", color: "blue")
    }
    
    override func tearDown() {
        folder = nil
        super.tearDown()
    }
    
    func testFolderInitialization() {
        XCTAssertNotNil(folder.id)
        XCTAssertEqual(folder.name, "测试文件夹")
        XCTAssertEqual(folder.color, "blue")
        XCTAssertTrue(folder.notebookIds.isEmpty)
    }
    
    func testAddNotebook() {
        let notebookId = UUID()
        folder.addNotebook(notebookId)
        
        XCTAssertEqual(folder.notebookIds.count, 1)
        XCTAssertTrue(folder.notebookIds.contains(notebookId))
    }
    
    func testRemoveNotebook() {
        let notebookId = UUID()
        folder.addNotebook(notebookId)
        folder.removeNotebook(notebookId)
        
        XCTAssertTrue(folder.notebookIds.isEmpty)
    }
}

/// 大纲测试
final class OutlineTests: XCTestCase {
    
    var outline: NotebookOutline!
    var notebook: Notebook!
    
    override func setUp() {
        super.setUp()
        notebook = Notebook(title: "测试", coverColor: "blue")
        outline = NotebookOutline.generate(from: notebook)
    }
    
    override func tearDown() {
        outline = nil
        notebook = nil
        super.tearDown()
    }
    
    func testGenerateOutline() {
        XCTAssertFalse(outline.items.isEmpty)
        XCTAssertEqual(outline.items.count, notebook.pages.count)
    }
    
    func testAddItem() {
        let item = OutlineItem(title: "新项目", pageIndex: 0)
        outline.addItem(item)
        
        XCTAssertEqual(outline.items.count, notebook.pages.count + 1)
    }
    
    func testRemoveItem() {
        let itemId = outline.items.first!.id
        outline.removeItem(id: itemId)
        
        XCTAssertEqual(outline.items.count, notebook.pages.count - 1)
    }
}
