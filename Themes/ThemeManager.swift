import SwiftUI

/// 主题配置
struct AppTheme: Identifiable, Codable {
    var id: UUID
    var name: String
    var isDark: Bool
    
    // 颜色
    var primaryColor: String      // 十六进制
    var secondaryColor: String
    var backgroundColor: String
    var surfaceColor: String
    var textColor: String
    var accentColor: String
    
    // 笔记封面颜色
    var notebookColors: [String]
    
    /// 默认主题
    static let `default` = AppTheme(
        id: UUID(),
        name: "默认",
        isDark: false,
        primaryColor: "#007AFF",
        secondaryColor: "#5856D6",
        backgroundColor: "#F2F2F7",
        surfaceColor: "#FFFFFF",
        textColor: "#000000",
        accentColor: "#FF9500",
        notebookColors: ["#007AFF", "#FF3B30", "#34C759", "#FF9500", "#5856D6", "#FF2D55"]
    )
    
    /// 夜间主题
    static let night = AppTheme(
        id: UUID(),
        name: "夜间",
        isDark: true,
        primaryColor: "#0A84FF",
        secondaryColor: "#5E5CE6",
        backgroundColor: "#000000",
        surfaceColor: "#1C1C1E",
        textColor: "#FFFFFF",
        accentColor: "#FF9F0A",
        notebookColors: ["#0A84FF", "#FF453A", "#30D158", "#FF9F0A", "#5E5CE6", "#FF375F"]
    )
    
    /// 柔和主题
    static let soft = AppTheme(
        id: UUID(),
        name: "柔和",
        isDark: false,
        primaryColor: "#FFB3C6",
        secondaryColor: "#B3D4FF",
        backgroundColor: "#FFF5F7",
        surfaceColor: "#FFFFFF",
        textColor: "#4A4A4A",
        accentColor: "#FF8FAB",
        notebookColors: ["#FFB3C6", "#B3D4FF", "#B3FFD4", "#FFE5B3", "#D4B3FF", "#FFB3E5"]
    )
    
    /// 经典主题
    static let classic = AppTheme(
        id: UUID(),
        name: "经典",
        isDark: false,
        primaryColor: "#8B4513",
        secondaryColor: "#D2691E",
        backgroundColor: "#FFF8DC",
        surfaceColor: "#FFFFF0",
        textColor: "#3E2723",
        accentColor: "#CD853F",
        notebookColors: ["#8B4513", "#A0522D", "#D2691E", "#CD853F", "#DEB887", "#F5DEB3"]
    )
    
    // 所有预设主题
    static let presets: [AppTheme] = [.default, .night, .soft, .classic]
}

/// 主题管理器
final class ThemeManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var currentTheme: AppTheme = .default
    @Published var customThemes: [AppTheme] = []
    
    // MARK: - 初始化
    
    init() {
        loadTheme()
    }
    
    // MARK: - 方法
    
    /// 加载保存的主题
    private func loadTheme() {
        if let data = UserDefaults.standard.data(forKey: "currentTheme"),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            currentTheme = theme
        }
        
        if let data = UserDefaults.standard.data(forKey: "customThemes"),
           let themes = try? JSONDecoder().decode([AppTheme].self, from: data) {
            customThemes = themes
        }
    }
    
    /// 保存主题
    private func saveTheme() {
        if let data = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(data, forKey: "currentTheme")
        }
    }
    
    /// 切换主题
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    /// 保存自定义主题
    func saveCustomTheme(_ theme: AppTheme) {
        customThemes.append(theme)
        
        if let data = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(data, forKey: "customThemes")
        }
    }
    
    /// 删除自定义主题
    func deleteCustomTheme(_ theme: AppTheme) {
        customThemes.removeAll { $0.id == theme.id }
        
        if let data = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(data, forKey: "customThemes")
        }
    }
    
    /// 重置为默认
    func resetToDefault() {
        currentTheme = .default
        saveTheme()
    }
}

// MARK: - 主题预览视图

struct ThemePreview: View {
    let theme: AppTheme
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // 预览卡片
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: theme.surfaceColor) ?? .white)
                    .frame(width: 80, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: theme.primaryColor) ?? .blue)
                        .frame(width: 20, height: 20)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 2)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 2)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            // 主题名称
            Text(theme.name)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
        }
    }
}

// MARK: - 主题选择器视图

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var showingCustomThemeEditor = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 预设主题
                Text("预设主题")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 90))
                ], spacing: 16) {
                    ForEach(AppTheme.presets) { theme in
                        ThemePreview(
                            theme: theme,
                            isSelected: themeManager.currentTheme.id == theme.id
                        )
                        .onTapGesture {
                            themeManager.setTheme(theme)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // 自定义主题
                HStack {
                    Text("自定义主题")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { showingCustomThemeEditor = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .padding(.horizontal)
                
                if themeManager.customThemes.isEmpty {
                    Text("暂无自定义主题")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90))
                    ], spacing: 16) {
                        ForEach(themeManager.customThemes) { theme in
                            ThemePreview(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id
                            )
                            .onTapGesture {
                                themeManager.setTheme(theme)
                            }
                            .contextMenu {
                                Button("删除", role: .destructive) {
                                    themeManager.deleteCustomTheme(theme)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("主题")
        .sheet(isPresented: $showingCustomThemeEditor) {
            CustomThemeEditorView(themeManager: themeManager)
        }
    }
}

// MARK: - 自定义主题编辑器

struct CustomThemeEditorView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = "新主题"
    @State private var isDark: Bool = false
    @State private var primaryColor: String = "#007AFF"
    @State private var backgroundColor: String = "#F2F2F7"
    @State private var surfaceColor: String = "#FFFFFF"
    @State private var textColor: String = "#000000"
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("主题名称", text: $name)
                    Toggle("深色模式", isOn: $isDark)
                }
                
                Section("颜色") {
                    ColorPickerRow(title: "主色", color: $primaryColor)
                    ColorPickerRow(title: "背景色", color: $backgroundColor)
                    ColorPickerRow(title: "表面色", color: $surfaceColor)
                    ColorPickerRow(title: "文字色", color: $textColor)
                }
                
                Section("预览") {
                    ThemePreview(theme: buildTheme())
                }
            }
            .navigationTitle("创建主题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let theme = buildTheme()
                        themeManager.saveCustomTheme(theme)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func buildTheme() -> AppTheme {
        AppTheme(
            id: UUID(),
            name: name,
            isDark: isDark,
            primaryColor: primaryColor,
            secondaryColor: primaryColor,
            backgroundColor: backgroundColor,
            surfaceColor: surfaceColor,
            textColor: textColor,
            accentColor: primaryColor,
            notebookColors: AppTheme.default.notebookColors
        )
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Color(hex: color) ?? .blue
                .frame(width: 30, height: 30)
                .cornerRadius(15)
        }
    }
}
