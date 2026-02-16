import Foundation

/// 多语言管理器
/// 支持多语言切换
final class LocalizationManager: ObservableObject {
    
    // MARK: - 支持的语言
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case chinese = "zh-Hans"
        case chineseTraditional = "zh-Hant"
        case japanese = "ja"
        case korean = "ko"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "简体中文"
            case .chineseTraditional: return "繁體中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .chinese: return "🇨🇳"
            case .chineseTraditional: return "🇭🇰"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            case .spanish: return "🇪🇸"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            }
        }
    }
    
    // MARK: - Published 属性
    
    @Published var currentLanguage: Language = .english
    
    // MARK: - 初始化
    
    init() {
        loadSavedLanguage()
    }
    
    // MARK: - 方法
    
    /// 切换语言
    func setLanguage(_ language: Language) {
        currentLanguage = language
        
        // 保存到 UserDefaults
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        
        // 通知系统更新语言
        NotificationCenter.default.post(name: .languageChanged, object: language)
    }
    
    /// 加载保存的语言
    private func loadSavedLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // 使用系统语言
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            
            if let matched = Language.allCases.first(where: { $0.rawValue.hasPrefix(systemLanguage) }) {
                currentLanguage = matched
            }
        }
    }
}

// MARK: - 通知

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - 本地化字符串

/// 本地化字符串管理器
final class LocalizedStrings {
    
    /// 获取本地化字符串
    static func get(_ key: String) -> String {
        // 这里可以从语言文件中加载
        // 简化实现使用字典
        return localizationDict[key] ?? key
    }
    
    /// 本地化字典
    private static let localizationDict: [String: [String: String]] = [
        // 通用
        "ok": ["en": "OK", "zh-Hans": "确定", "zh-Hant": "確定", "ja": "OK", "ko": "확인", "es": "Aceptar", "fr": "OK", "de": "OK"],
        "cancel": ["en": "Cancel", "zh-Hans": "取消", "zh-Hant": "取消", "ja": "キャンセル", "ko": "취소", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen"],
        "save": ["en": "Save", "zh-Hans": "保存", "zh-Hant": "儲存", "ja": "保存", "ko": "저장", "es": "Guardar", "fr": "Enregistrer", "de": "Speichern"],
        "delete": ["en": "Delete", "zh-Hans": "删除", "zh-Hant": "刪除", "ja": "削除", "ko": "삭제", "es": "Eliminar", "fr": "Supprimer", "de": "Löschen"],
        "edit": ["en": "Edit", "zh-Hans": "编辑", "zh-Hant": "編輯", "ja": "編集", "ko": "편집", "es": "Editar", "fr": "Modifier", "de": "Bearbeiten"],
        
        // 笔记本
        "notebooks": ["en": "Notebooks", "zh-Hans": "笔记本", "zh-Hant": "筆記本", "ja": "ノートブック", "ko": "노트북", "es": "Cuadernos", "fr": "Cahiers", "de": "Notizbücher"],
        "newNotebook": ["en": "New Notebook", "zh-Hans": "新建笔记本", "zh-Hant": "新建筆記本", "ja": "新規ノートブック", "ko": "새 노트북", "es": "Nuevo Cuaderno", "fr": "Nouveau Cahier", "de": "Neues Notizbuch"],
        "notebookTitle": ["en": "Title", "zh-Hans": "标题", "zh-Hant": "標題", "ja": "タイトル", "ko": "제목", "es": "Título", "fr": "Titre", "de": "Titel"],
        
        // 页面
        "pages": ["en": "Pages", "zh-Hans": "页面", "zh-Hant": "頁面", "ja": "ページ", "ko": "페이지", "es": "Páginas", "fr": "Pages", "de": "Seiten"],
        "newPage": ["en": "New Page", "zh-Hans": "新建页面", "zh-Hant": "新建頁面", "ja": "新規ページ", "ko": "새 페이지", "es": "Nueva Página", "fr": "Nouvelle Page", "de": "Neue Seite"],
        
        // 工具
        "pen": ["en": "Pen", "zh-Hans": "钢笔", "zh-Hant": "鋼筆", "ja": "ペン", "ko": "펜", "es": "Pluma", "fr": "Stylo", "de": "Stift"],
        "highlighter": ["en": "Highlighter", "zh-Hans": "荧光笔", "zh-Hant": "螢光筆", "ja": "ハイライター", "ko": "형광펜", "es": "Resaltador", "fr": "Surligneur", "de": "Textmarker"],
        "eraser": ["en": "Eraser", "zh-Hans": "橡皮擦", "zh-Hant": "橡皮擦", "ja": "消しゴム", "ko": "지우개", "es": "Borrador", "fr": "Gomme", "de": "Radierer"],
        
        // 设置
        "settings": ["en": "Settings", "zh-Hans": "设置", "zh-Hant": "設定", "ja": "設定", "ko": "설정", "es": "Ajustes", "fr": "Paramètres", "de": "Einstellungen"],
        "language": ["en": "Language", "zh-Hans": "语言", "zh-Hant": "語言", "ja": "言語", "ko": "언어", "es": "Idioma", "fr": "Langue", "de": "Sprache"],
        "theme": ["en": "Theme", "zh-Hans": "主题", "zh-Hant": "主題", "ja": "テーマ", "ko": "테마", "es": "Tema", "fr": "Thème", "de": "Design"],
        
        // 其他
        "search": ["en": "Search", "zh-Hans": "搜索", "zh-Hant": "搜索", "ja": "検索", "ko": "검색", "es": "Buscar", "fr": "Rechercher", "de": "Suchen"],
        "export": ["en": "Export", "zh-Hans": "导出", "zh-Hant": "導出", "ja": "エクスポート", "ko": "내보내기", "es": "Exportar", "fr": "Exporter", "de": "Exportieren"],
        "import": ["en": "Import", "zh-Hans": "导入", "zh-Hant": "導入", "ja": "インポート", "ko": "가져오기", "es": "Importar", "fr": "Importer", "de": "Importieren"],
    ]
    
    /// 获取当前语言的字符串
    static func localized(_ key: String) -> String {
        let currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        
        if let translations = localizationDict[key],
           let translation = translations[currentLanguage] {
            return translation
        }
        
        // 默认返回英文
        return localizationDict[key]?["en"] ?? key
    }
}

// MARK: - 字符串键

/// 本地化键
enum LocalizedKey: String {
    case ok = "ok"
    case cancel = "cancel"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    case notebooks = "notebooks"
    case newNotebook = "newNotebook"
    case notebookTitle = "notebookTitle"
    case pages = "pages"
    case newPage = "newPage"
    case pen = "pen"
    case highlighter = "highlighter"
    case eraser = "eraser"
    case settings = "settings"
    case language = "language"
    case theme = "theme"
    case search = "search"
    case export = "export"
    case import_ = "import"
    
    var string: String {
        LocalizedStrings.localized(rawValue)
    }
}
