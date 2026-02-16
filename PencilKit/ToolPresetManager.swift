import Foundation
import PencilKit

/// PencilKit 工具预设
/// 提供常用绘画工具的预设配置
struct ToolPreset: Identifiable, Codable {
    var id: UUID
    var name: String
    var toolType: String  // "pen", "marker", "pencil", "highlighter"
    var color: String
    var width: Double
    var isEraser: Bool
    
    init(id: UUID = UUID(), name: String, toolType: String, color: String, width: Double, isEraser: Bool = false) {
        self.id = id
        self.name = name
        self.toolType = toolType
        self.color = color
        self.width = width
        self.isEraser = isEraser
    }
    
    /// 转换为 PKTool
    func toPKTool() -> PKTool {
        let uiColor = UIColor(hex: color) ?? .black
        
        if isEraser {
            return PKEraserTool(.bitmap)
        }
        
        switch toolType {
        case "pen":
            return PKInkingTool(.pen, color: uiColor, width: width)
        case "marker":
            return PKInkingTool(.marker, color: uiColor, width: width)
        case "pencil":
            return PKInkingTool(.pencil, color: uiColor, width: width)
        case "highlighter":
            return PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.3), width: width * 3)
        default:
            return PKInkingTool(.pen, color: uiColor, width: width)
        }
    }
}

/// 预设管理器
final class ToolPresetManager: ObservableObject {
    
    // MARK: - 默认预设
    
    static let defaultPresets: [ToolPreset] = [
        ToolPreset(name: "钢笔-细", toolType: "pen", color: "#000000", width: 1.5),
        ToolPreset(name: "钢笔-中", toolType: "pen", color: "#000000", width: 3.0),
        ToolPreset(name: "钢笔-粗", toolType: "pen", color: "#000000", width: 5.0),
        ToolPreset(name: "马克笔", toolType: "marker", color: "#FF9500", width: 10.0),
        ToolPreset(name: "荧光笔", toolType: "highlighter", color: "#FFCC00", width: 15.0),
        ToolPreset(name: "铅笔", toolType: "pencil", color: "#4A4A4A", width: 2.0),
    ]
    
    // MARK: - Published 属性
    
    @Published var presets: [ToolPreset] = []
    @Published var selectedPreset: ToolPreset?
    
    // MARK: - 初始化
    
    init() {
        loadPresets()
    }
    
    // MARK: - 方法
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "toolPresets"),
           let saved = try? JSONDecoder().decode([ToolPreset].self, from: data) {
            presets = saved
        } else {
            presets = Self.defaultPresets
        }
    }
    
    func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "toolPresets")
        }
    }
    
    func addPreset(_ preset: ToolPreset) {
        presets.append(preset)
        savePresets()
    }
    
    func removePreset(_ preset: ToolPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
    
    func resetToDefaults() {
        presets = Self.defaultPresets
        savePresets()
    }
}

// MARK: - 画笔工具设置

import SwiftUI

struct ToolSettingsView: View {
    @ObservedObject var presetManager: ToolPresetManager
    @State private var newPresetName: String = ""
    @State private var selectedType: String = "pen"
    @State private var selectedColor: Color = .black
    @State private var strokeWidth: Double = 3.0
    
    var body: some View {
        List {
            Section("预设工具") {
                ForEach(presetManager.presets) { preset in
                    Button(action: { selectPreset(preset) }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: preset.color) ?? .black)
                                .frame(width: 20, height: 20)
                            
                            Text(preset.name)
                            
                            Spacer()
                            
                            if presetManager.selectedPreset?.id == preset.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        presetManager.removePreset(presetManager.presets[index])
                    }
                }
            }
            
            Section("创建新预设") {
                TextField("预设名称", text: $newPresetName)
                
                Picker("工具类型", selection: $selectedType) {
                    Text("钢笔").tag("pen")
                    Text("马克笔").tag("marker")
                    Text("铅笔").tag("pencil")
                    Text("荧光笔").tag("highlighter")
                }
                
                ColorPicker("颜色", selection: $selectedColor)
                
                Slider("粗细", value: $strokeWidth, in: 0.5...30)
                
                Button("保存为新预设") {
                    saveNewPreset()
                }
                .disabled(newPresetName.isEmpty)
            }
            
            Section {
                Button("重置为默认") {
                    presetManager.resetToDefaults()
                }
            }
        }
    }
    
    private func selectPreset(_ preset: ToolPreset) {
        presetManager.selectedPreset = preset
    }
    
    private func saveNewPreset() {
        let preset = ToolPreset(
            name: newPresetName,
            toolType: selectedType,
            color: selectedColor.toHex() ?? "#000000",
            width: strokeWidth
        )
        presetManager.addPreset(preset)
        
        newPresetName = ""
    }
}

// MARK: - Color 扩展

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
