/**
 * Firebase 配置文件
 * 
 * 使用方法：
 * 1. 在 Firebase Console (https://console.firebase.google.com) 创建项目
 * 2. 添加 iOS 应用，下载 GoogleService-Info.plist
 * 3. 将下载的文件内容填入下方配置
 * 4. 启用登录方式：Apple、Google、WeChat、Email
 * 
 * 注意：WeChat 登录需要：
 * - 微信开放平台账号 (https://open.weixin.qq.com)
 * - 在 Firebase 中配置微信 App ID 和 Secret
 */

import Foundation

struct FirebaseConfig {
    // ==================== 替换为你的配置 ====================
    
    /// API Key
    #warning("请替换以下 Firebase 配置为您自己的真实凭据")
    static let apiKey = "YOUR_API_KEY"
    
    /// Bundle ID (在 Xcode 中查看)
    static let bundleID = "com.yourteam.ClawNotes"
    
    /// 项目 ID (Firebase Console -> 项目设置 -> 常规)
    static let projectID = "your-project-id"
    
    /// 存储桶
    static let storageBucket = "your-project-id.appspot.com"
    
    /// Google 客户端 ID (用于 Google 登录)
    static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
    
    /// 广告 ID (可选)
    static let gcmSenderID = "YOUR_GCM_SENDER_ID"
    
    /// Android ID (如果也做 Android)
    static let androidClientID = "YOUR_ANDROID_CLIENT_ID"
    
    /// 深度链接 URL Scheme
    static let deepLinkURLScheme = "clawnotes"
    
    // ========================================================
}

/**
 * 登录方式配置
 */
enum AuthProvider: String, CaseIterable {
    case apple = "apple.com"
    case google = "google.com"
    case wechat = "wechat.com"
    case email = "password"
    case anonymous = "anonymous"
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .wechat: return "WeChat"
        case .email: return "Email"
        case .anonymous: return "游客"
        }
    }
    
    var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .wechat: return "message.circle.fill"
        case .email: return "envelope.fill"
        case .anonymous: return "person.circle.fill"
        }
    }
}
