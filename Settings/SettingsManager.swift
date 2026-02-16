import SwiftUI

/// 应用设置管理器
final class SettingsManager: ObservableObject {
    
    // MARK: - 设置结构
    
    struct AppSettings: Codable {
        // 通用
        var autoSave: Bool = true
        var autoSaveInterval: Int = 30  // 秒
        
        // 笔记
        var defaultTemplate: String = "blank"
        var defaultNotebookColor: String = "blue"
        var showPageNumbers: Bool = true
        
        // 工具栏
        var showToolBar: Bool = true
        var toolBarPosition: String = "bottom"  // "bottom", "top", "floating"
        var quickColorCount: Int = 10
        
        // 手势
        var twoFingerUndo: Bool = true
        var palmRejection: Bool = true
        var doubleTapToZoom: Bool = true
        
        // 同步
        var syncOnCellular: Bool = false
        var syncWiFiOnly: Bool = true
        
        // 存储
        var maxCacheSize: Int = 500  // MB
        var autoCleanupCache: Bool = true
        
        // 界面
        var defaultViewMode: String = "single"  // "single", "double", "scroll"
        var showThumbnailSidebar: Bool = true
        
        // 隐私
        var analyticsEnabled: Bool = false
        var crashReportingEnabled: Bool = true
    }
    
    // MARK: - Published 属性
    
    @Published var settings = AppSettings()
    
    // MARK: - 初始化
    
    init() {
        loadSettings()
    }
    
    // MARK: - 方法
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let saved = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = saved
        }
    }
    
    func saveSettings() {
        if let dataEncoder().encode(settings = try? JSON) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
    
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }
}

// MARK: - 设置视图

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var securityManager: SecurityManager
    
    var body: some View {
        Form {
            // 通用设置
            Section("通用") {
                Toggle("自动保存", isOn: $settingsManager.settings.autoSave)
                
                if settingsManager.settings.autoSave {
                    Picker("自动保存间隔", selection: $settingsManager.settings.autoSaveInterval) {
                        Text("15 秒").tag(15)
                        Text("30 秒").tag(30)
                        Text("1 分钟").tag(60)
                        Text("5 分钟").tag(300)
                    }
                }
            }
            
            // 笔记设置
            Section("笔记") {
                Picker("默认模板", selection: $settingsManager.settings.defaultTemplate) {
                    Text("空白").tag("blank")
                    Text("横线").tag("lined")
                    Text("网格").tag("grid")
                    Text("点阵").tag("dotted")
                }
                
                Toggle("显示页码", isOn: $settingsManager.settings.showPageNumbers)
                
                Picker("默认视图", selection: $settingsManager.settings.defaultViewMode) {
                    Text("单页").tag("single")
                    Text("双页").tag("double")
                    Text("滚动").tag("scroll")
                }
            }
            
            // 工具栏
            Section("工具栏") {
                Toggle("显示工具栏", isOn: $settingsManager.settings.showToolBar)
                
                Picker("工具栏位置", selection: $settingsManager.settings.toolBarPosition) {
                    Text("底部").tag("bottom")
                    Text("顶部").tag("top")
                    Text("悬浮").tag("floating")
                }
            }
            
            // 手势
            Section("手势") {
                Toggle("双指撤销", isOn: $settingsManager.settings.twoFingerUndo)
                Toggle("手掌防误触", isOn: $settingsManager.settings.palmRejection)
                Toggle("双击缩放", isOn: $settingsManager.settings.doubleTapToZoom)
            }
            
            // 同步
            Section("同步") {
                Toggle("移动网络同步", isOn: $settingsManager.settings.syncOnCellular)
                Toggle("仅 WiFi 同步", isOn: $settingsManager.settings.syncWiFiOnly)
            }
            
            // 存储
            Section("存储") {
                HStack {
                    Text("最大缓存")
                    Spacer()
                    Picker("", selection: $settingsManager.settings.maxCacheSize) {
                        Text("100 MB").tag(100)
                        Text("500 MB").tag(500)
                        Text("1 GB").tag(1000)
                        Text("2 GB").tag(2000)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Toggle("自动清理缓存", isOn: $settingsManager.settings.autoCleanupCache)
            }
            
            // 隐私
            Section("隐私") {
                Toggle("分析", isOn: $settingsManager.settings.analyticsEnabled)
                Toggle("崩溃报告", isOn: $settingsManager.settings.crashReportingEnabled)
            }
            
            // 快捷入口
            Section("快捷入口") {
                NavigationLink("主题", destination: ThemePickerView(themeManager: themeManager))
                NavigationLink("安全", destination: SecuritySettingsView(securityManager: securityManager))
            }
            
            // 关于
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Button("重置所有设置") {
                    settingsManager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .onChange(of: settingsManager.settings) { _ in
            settingsManager.saveSettings()
        }
    }
}
