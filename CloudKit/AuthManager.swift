/**
 * 认证管理器
 * 
 * 功能：
 * - Apple ID 登录
 * - Google 登录
 * - WeChat 登录
 * - Email/Password 登录
 * - 匿名登录
 * - 获取当前用户
 * - 登出
 * 
 * 使用方法：
 * 1. 在 Firebase Console 启用相应的登录方式
 * 2. 在 Xcode 中配置 URL Schemes
 * 3. 在 AppDelegate 中调用 AuthManager.shared.handleURL(url)
 */

import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
import AuthenticationServices
import CryptoKit

/// 认证状态
enum AuthState {
    case undefined
    case signedIn(User)
    case signedOut
}

/// 认证错误
enum AuthError: LocalizedError {
    case notConfigured
    case signInFailed(String)
    case linkFailed(String)
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase 未配置"
        case .signInFailed(let message):
            return "登录失败: \(message)"
        case .linkFailed(let message):
            return "账号绑定失败: \(message)"
        case .invalidToken:
            return "无效的 Token"
        }
    }
}

/// 认证管理器 (单例)
final class AuthManager: NSObject, ObservableObject {
    
    // MARK: - 单例
    
    static let shared = AuthManager()
    
    // MARK: - Published 属性
    
    @Published var currentUser: User?
    @Published var authState: AuthState = .undefined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    // MARK: - 初始化
    
    private override init() {
        super.init()
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - 监听认证状态
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                if let user = user {
                    self?.authState = .signedIn(user)
                } else {
                    self?.authState = .signedOut
                }
            }
        }
    }
    
    // MARK: - 匿名登录
    
    /// 匿名登录
    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("匿名登录成功: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Email 登录
    
    /// Email 注册
    func createUser(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("用户注册成功: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    /// Email 登录
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("Email 登录成功: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Google 登录
    
    /// Google 登录
    /// 需要在 Xcode 中配置 URL Schemes: REVERSE_CLIENT_ID
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 获取 Google 登录配置
        guard let clientID = FirebaseConfig.clientID.components(separatedBy: ".").first else {
            throw AuthError.notConfigured
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            let user = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = user.user.idToken?.tokenString else {
                throw AuthError.invalidToken
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.user.accessToken.tokenString)
            
            let result = try await Auth.auth().signIn(with: credential)
            print("Google 登录成功: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Apple 登录
    
    /// Apple 登录
    func signInWithApple(presenting viewController: UIViewController) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        // 注意: 这个方法需要包装成 async/await
        // 实际实现需要使用 continuation
        controller.performRequests()
        
        // 由于 Apple 登录是异步回调，这里需要特殊处理
        // 建议使用第三方库或包装
    }
    
    /// 处理 Apple 登录回调
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let token = credential.identityToken,
              let tokenString = String(data: token, encoding: .utf8) else {
            throw AuthError.invalidToken
        }
        
        let nonce = currentNonce
        currentNonce = nil
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        
        do {
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            print("Apple 登录成功: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - WeChat 登录
    
    /// WeChat 登录
    /// 需要安装微信 App 并配置 URL Schemes
    /// 同时需要在 Firebase Console 配置微信登录
    func signInWithWeChat() async throws {
        // WeChat 登录需要:
        // 1. 在微信开放平台注册应用
        // 2. 配置 URL Schemes
        // 3. 在 Firebase Console 添加微信登录
        
        // 简化实现: 使用通用 Web 登录
        // 实际需要使用微信 SDK
        
        throw AuthError.signInFailed("WeChat 登录需要配置微信 SDK")
    }
    
    // MARK: - Token 管理
    
    /// 获取当前 ID Token
    func getIDToken() async -> String? {
        return await currentUser?.getIDToken()
    }
    
    /// 刷新 Token
    func refreshToken() async {
        do {
            _ = try await currentUser?.getIDToken(true)
            print("Token 刷新成功")
        } catch {
            print("Token 刷新失败: \(error)")
        }
    }
    
    // MARK: - 登出
    
    /// 登出
    func signOut() throws {
        try Auth.auth().signOut()
        print("已登出")
    }
    
    /// 删除账户
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.signInFailed("没有登录的用户")
        }
        
        do {
            try await user.delete()
            print("账户已删除")
        } catch {
            // 如果是最近登录的账户，需要重新验证
            if let error = error as? NSError,
               error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw AuthError.signInFailed("请重新登录后再删除账户")
            }
            throw error
        }
    }
    
    // MARK: - URL 处理
    
    /// 处理 URL (在 AppDelegate 或 SceneDelegate 中调用)
    func handleURL(_ url: URL) -> Bool {
        // Google 登录回调
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // 其他 URL 处理
        return false
    }
    
    // MARK: - 私有方法
    
    private func randomNonceString() -> String {
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(nonce.prefix(32))
    }
    
    private func sha256(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        Task {
            try? await handleAppleSignIn(credential: credential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
        print("Apple 登录失败: \(error)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // iOS 15+ 安全获取 key window
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}
