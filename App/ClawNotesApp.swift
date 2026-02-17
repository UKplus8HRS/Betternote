//
//  ClawNotes - BetterNotes
//  iPad Note-Taking App
//
//  Created by Vibecoding with AI Assistant
//  Copyright © 2026. All rights reserved.
//
//  https://github.com/UKplus8HRS/Betternote
//

import SwiftUI
import PencilKit
import CloudKit
import Vision
import Speech

/// 应用入口
/// 程序从这里开始执行
@main
struct ClawNotesApp: App {
    
    /// 全局 ViewModel
    @StateObject private var notebookVM = NotebookViewModel()
    
    /// 主题管理器
    @StateObject private var themeManager = ThemeManager()
    
    /// 安全管理器
    @StateObject private var securityManager = SecurityManager()
    
    /// 初始化
    init() {
        // 配置应用
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notebookVM)
                .environmentObject(themeManager)
                .environmentObject(securityManager)
        }
    }
    
    /// 配置应用设置
    private func configureApp() {
        // 应用初始化配置
        // 未来可在此添加全局配置逻辑
    }
}

// MARK: - 快捷访问

/// 全局常量
enum AppConstants {
    /// 应用名称
    static let appName = "ClawNotes"
    
    /// Bundle ID
    static let bundleID = "com.betternotes.app"
    
    /// 版本
    static let version = "1.0.0"
    
    /// 最大标签页数
    static let maxTabs = 10
    
    /// 最大撤销次数
    static let maxUndoCount = 50
    
    /// 自动保存间隔 (秒)
    static let autoSaveInterval: TimeInterval = 30
    
    /// 默认页面大小
    static let defaultPageSize = CGSize(width: 612, height: 792)
    
    /// 支持的语言
    static let supportedLanguages = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de"]
}

// MARK: - 颜色扩展
// 注意: Color(hex:) init 定义在 EnhancedToolBar.swift 中，全局可用

// MARK: - 日期扩展

extension Date {
    /// 格式化日期为本地化字符串
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 相对时间
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - 字符串扩展

extension String {
    /// 是否为空
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 截断字符串
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count <= length {
            return self
        }
        return String(prefix(length)) + trailing
    }
}

// MARK: - 数组扩展

extension Array {
    /// 安全获取元素
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View 扩展

extension View {
    /// 条件修改器
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 应用主题颜色
    func themedBackground(_ colorName: String) -> some View {
        self.background(Color(hex: colorName) ?? .clear)
    }
}

// MARK: - Notification 名称

extension Notification.Name {
    /// 数据已同步
    static let dataDidSync = Notification.Name("dataDidSync")
    
    /// 主题已更改
    static let themeDidChange = Notification.Name("themeDidChange")
    
    /// 需要解锁
    static let requireUnlock = Notification.Name("requireUnlock")
}
