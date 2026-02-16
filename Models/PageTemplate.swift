import Foundation

/// 页面模板类型
/// 用于创建不同类型的空白页面
enum PageTemplate: String, Codable, CaseIterable {
    case blank = "blank"           // 空白
    case lined = "lined"           // 横线
    case grid = "grid"             // 网格
    case dotted = "dotted"        // 点阵
    case checklist = "checklist"   // 待办清单
    case calendar = "calendar"     // 日历
    
    var displayName: String {
        switch self {
        case .blank: return "空白"
        case .lined: return "横线"
        case .grid: return "网格"
        case .dotted: return "点阵"
        case .checklist: return "待办"
        case .calendar: return "日历"
        }
    }
    
    var iconName: String {
        switch self {
        case .blank: return "doc"
        case .lined: return "text.alignleft"
        case .grid: return "grid"
        case .dotted: return "circle.grid.3x3"
        case .checklist: return "checklist"
        case .calendar: return "calendar"
        }
    }
}

/// 页面模板模型
struct PageTemplateModel: Identifiable {
    let id = UUID()
    let template: PageTemplate
    let backgroundColor: String  // 十六进制颜色
    
    static let templates: [PageTemplateModel] = [
        PageTemplateModel(template: .blank, backgroundColor: "#FFFFFF"),
        PageTemplateModel(template: .lined, backgroundColor: "#FFFDE7"),
        PageTemplateModel(template: .grid, backgroundColor: "#F5F5F5"),
        PageTemplateModel(template: .dotted, backgroundColor: "#FFFEF0"),
        PageTemplateModel(template: .checklist, backgroundColor: "#FFFDE7"),
        PageTemplateModel(template: .calendar, backgroundColor: "#FFFFFF"),
    ]
}
