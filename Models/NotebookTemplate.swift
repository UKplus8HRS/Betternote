import Foundation

/// 模板类型
enum TemplateCategory: String, Codable, CaseIterable {
    case study = "study"
    case work = "work"
    case life = "life"
    case creative = "creative"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .study: return "学习"
        case .work: return "工作"
        case .life: return "生活"
        case .creative: return "创意"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .life: return "house.fill"
        case .creative: return "paintbrush.fill"
        case .custom: return "star.fill"
        }
    }
}

/// 笔记本模板
struct NotebookTemplate: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var category: TemplateCategory
    var coverColor: String
    var pages: [PageTemplate]
    var tags: [String]
    var isBuiltIn: Bool  // 是否内置
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: TemplateCategory,
        coverColor: String,
        pages: [PageTemplate],
        tags: [String] = [],
        isBuiltIn: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.coverColor = coverColor
        self.pages = pages
        self.tags = tags
        self.isBuiltIn = isBuiltIn
    }
    
    /// 从模板创建笔记本
    func createNotebook() -> Notebook {
        let notebook = Notebook(title: name, coverColor: coverColor)
        
        // 根据模板创建页面
        var newPages: [NotePage] = []
        for template in pages {
            let page = NotePage(template: template, backgroundColor: "#FFFFFF")
            newPages.append(page)
        }
        
        return Notebook(
            id: UUID(),
            title: name,
            coverColor: coverColor,
            pages: newPages.isEmpty ? [NotePage()] : newPages
        )
    }
}

/// 模板管理器
final class TemplateManager: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var templates: [NotebookTemplate] = []
    @Published var customTemplates: [NotebookTemplate] = []
    @Published var selectedCategory: TemplateCategory?
    
    // MARK: - 初始化
    
    init() {
        loadBuiltInTemplates()
    }
    
    // MARK: - 内置模板
    
    private func loadBuiltInTemplates() {
        templates = [
            // ===== 学习类 =====
            NotebookTemplate(
                name: "单词笔记本",
                description: "记录英语单词、短语和例句",
                category: .study,
                coverColor: "#007AFF",
                pages: [.lined, .lined, .lined],
                tags: ["英语", "学习", "语言"]
            ),
            NotebookTemplate(
                name: "数学错题本",
                description: "记录做错的数学题目和解析",
                category: .study,
                coverColor: "#FF3B30",
                pages: [.grid, .blank, .blank],
                tags: ["数学", "错题", "考试"]
            ),
            NotebookTemplate(
                name: "课堂笔记",
                description: "通用的课堂记录模板",
                category: .study,
                coverColor: "#34C759",
                pages: [.lined, .lined, .blank],
                tags: ["笔记", "学习", "通用"]
            ),
            NotebookTemplate(
                name: "读书笔记",
                description: "记录书籍阅读心得和重点",
                category: .study,
                coverColor: "#5856D6",
                pages: [.blank, .lined, .blank],
                tags: ["阅读", "书籍", "心得"]
            ),
            
            // ===== 工作类 =====
            NotebookTemplate(
                name: "会议记录",
                description: "记录会议要点、议程和待办事项",
                category: .work,
                coverColor: "#FF9500",
                pages: [.blank, .checklist, .blank],
                tags: ["会议", "工作", "商务"]
            ),
            NotebookTemplate(
                name: "项目进度",
                description: "跟踪项目任务和里程碑",
                category: .work,
                coverColor: "#FF2D55",
                pages: [.checklist, .blank, .blank],
                tags: ["项目", "管理", "进度"]
            ),
            NotebookTemplate(
                name: "头脑风暴",
                description: "自由书写想法和创意",
                category: .work,
                coverColor: "#AF52DE",
                pages: [.blank, .blank, .blank],
                tags: ["创意", "头脑风暴", "想法"]
            ),
            NotebookTemplate(
                name: "待办清单",
                description: "日常任务和待办事项",
                category: .work,
                coverColor: "#00C7BE",
                pages: [.checklist, .checklist, .checklist],
                tags: ["待办", "任务", "日程"]
            ),
            
            // ===== 生活类 =====
            NotebookTemplate(
                name: "日记",
                description: "每日记录和生活感悟",
                category: .life,
                coverColor: "#FFB3C6",
                pages: [.blank, .lined],
                tags: ["日记", "生活", "记录"]
            ),
            NotebookTemplate(
                name: "旅行计划",
                description: "规划行程、景点和预算",
                category: .life,
                coverColor: "#30D158",
                pages: [.blank, .checklist, .blank],
                tags: ["旅行", "规划", "假期"]
            ),
            NotebookTemplate(
                name: "菜谱",
                description: "记录美味食谱和烹饪技巧",
                category: .life,
                coverColor: "#FFD60A",
                pages: [.blank, .lined, .blank],
                tags: ["菜谱", "烹饪", "美食"]
            ),
            NotebookTemplate(
                name: "健身记录",
                description: "追踪运动和健康数据",
                category: .life,
                coverColor: "#FF453A",
                pages: [.checklist, .blank, .blank],
                tags: ["健身", "运动", "健康"]
            ),
            
            // ===== 创意类 =====
            NotebookTemplate(
                name: "涂鸦本",
                description: "自由绘画和草图",
                category: .creative,
                coverColor: "#64D2FF",
                pages: [.blank, .blank, .blank, .blank],
                tags: ["绘画", "涂鸦", "创意"]
            ),
            NotebookTemplate(
                name: "乐谱",
                description: "记录音乐和歌曲",
                category: .creative,
                coverColor: "#BF5AF2",
                pages: [.blank, .blank, .blank],
                tags: ["音乐", "乐谱", "歌曲"]
            ),
            NotebookTemplate(
                name: "手账",
                description: "装饰性日记和拼贴",
                category: .creative,
                coverColor: "#FF375F",
                pages: [.blank, .blank, .blank],
                tags: ["手账", "拼贴", "装饰"]
            ),
            
            // ===== 更多学习类 =====
            NotebookTemplate(
                name: "化学笔记",
                description: "化学方程式和实验记录",
                category: .study,
                coverColor: "#32D74B",
                pages: [.blank, .blank, .blank],
                tags: ["化学", "实验", "方程式"]
            ),
            NotebookTemplate(
                name: "物理笔记",
                description: "物理公式和力学分析",
                category: .study,
                coverColor: "#0A84FF",
                pages: [.grid, .blank, .blank],
                tags: ["物理", "公式", "力学"]
            ),
            NotebookTemplate(
                name: "历史年表",
                description: "历史事件和时间线",
                category: .study,
                coverColor: "#8E8E93",
                pages: [.blank, .blank, .blank],
                tags: ["历史", "年表", "事件"]
            ),
            NotebookTemplate(
                name: "地理地图",
                description: "地图绘制和地理标注",
                category: .study,
                coverColor: "#30D158",
                pages: [.blank, .blank, .blank],
                tags: ["地理", "地图", "标注"]
            ),
            
            // ===== 更多工作类 =====
            NotebookTemplate(
                name: "周计划",
                description: "每周计划和目标追踪",
                category: .work,
                coverColor: "#FF9F0A",
                pages: [.checklist, .checklist, .checklist, .checklist, .checklist],
                tags: ["周计划", "目标", "追踪"]
            ),
            NotebookTemplate(
                name: "月度总结",
                description: "月度工作汇总和分析",
                category: .work,
                coverColor: "#5856D6",
                pages: [.blank, .lined, .blank],
                tags: ["月度", "总结", "分析"]
            ),
            NotebookTemplate(
                name: "客户管理",
                description: "客户信息和跟进记录",
                category: .work,
                coverColor: "#007AFF",
                pages: [.blank, .blank, .blank],
                tags: ["客户", "管理", "跟进"]
            ),
            NotebookTemplate(
                name: "财务笔记",
                description: "收支记录和预算规划",
                category: .work,
                coverColor: "#34C759",
                pages: [.checklist, .lined, .blank],
                tags: ["财务", "收支", "预算"]
            ),
            
            // ===== 更多生活类 =====
            NotebookTemplate(
                name: "电影清单",
                description: "想看和已看电影记录",
                category: .life,
                coverColor: "#FF375F",
                pages: [.checklist, .blank],
                tags: ["电影", "清单", "观影"]
            ),
            NotebookTemplate(
                name: "音乐播放列表",
                description: "喜欢的歌曲和专辑",
                category: .life,
                coverColor: "#BF5AF2",
                pages: [.blank, .checklist],
                tags: ["音乐", "歌曲", "专辑"]
            ),
            NotebookTemplate(
                name: "购物清单",
                description: "购物清单和比价记录",
                category: .life,
                coverColor: "#FF9500",
                pages: [.checklist, .checklist],
                tags: ["购物", "清单", "比价"]
            ),
            NotebookTemplate(
                name: "礼物清单",
                description: "礼物创意和购买记录",
                category: .life,
                coverColor: "#FF2D55",
                pages: [.checklist, .blank],
                tags: ["礼物", "创意", "节日"]
            ),
            NotebookTemplate(
                name: "灵感收集",
                description: "日常灵感和创意点子",
                category: .life,
                coverColor: "#64D2FF",
                pages: [.blank, .blank, .blank],
                tags: ["灵感", "创意", "点子"]
            ),
            
            // ===== 更多创意类 =====
            NotebookTemplate(
                name: "漫画草稿",
                description: "漫画分镜和草图",
                category: .creative,
                coverColor: "#FF6B6B",
                pages: [.blank, .blank, .blank, .blank, .blank],
                tags: ["漫画", "草稿", "分镜"]
            ),
            NotebookTemplate(
                name: "设计草图",
                description: "UI/UX 设计草图",
                category: .creative,
                coverColor: "#5E5CE6",
                pages: [.blank, .blank, .blank],
                tags: ["设计", "UI", "UX"]
            ),
            NotebookTemplate(
                name: "建筑草图",
                description: "建筑设计构思和草图",
                category: .creative,
                coverColor: "#AC8E68",
                pages: [.blank, .blank, .blank],
                tags: ["建筑", "设计", "草图"]
            ),
            NotebookTemplate(
                name: "服装设计",
                description: "服装设计和配色方案",
                category: .creative,
                coverColor: "#FFB3C6",
                pages: [.blank, .blank, .blank],
                tags: ["服装", "设计", "配色"]
            ),
        ]
    }
    
    // MARK: - 方法
    
    /// 获取分类后的模板
    func templates(for category: TemplateCategory) -> [NotebookTemplate] {
        templates.filter { $0.category == category }
    }
    
    /// 搜索模板
    func search(query: String) -> [NotebookTemplate] {
        let lowercased = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    /// 从模板创建笔记本
    func createNotebook(from template: NotebookTemplate) -> Notebook {
        return template.createNotebook()
    }
    
    /// 保存自定义模板
    func saveCustomTemplate(_ template: NotebookTemplate) {
        var custom = template
        custom.isBuiltIn = false
        customTemplates.append(custom)
        saveCustomTemplates()
    }
    
    /// 删除自定义模板
    func deleteCustomTemplate(_ template: NotebookTemplate) {
        customTemplates.removeAll { $0.id == template.id }
        saveCustomTemplates()
    }
    
    private func saveCustomTemplates() {
        if let data = try? JSONEncoder().encode(customTemplates) {
            UserDefaults.standard.set(data, forKey: "customTemplates")
        }
    }
    
    private func loadCustomTemplates() {
        if let data = UserDefaults.standard.data(forKey: "customTemplates"),
           let templates = try? JSONDecoder().decode([NotebookTemplate].self, from: data) {
            customTemplates = templates
        }
    }
}
