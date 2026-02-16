import Foundation
import LocalAuthentication

/// 安全管理器
/// 提供生物识别、密码保护、数据加密等功能
final class SecurityManager: ObservableObject {
    
    // MARK: - 安全设置
    
    struct SecuritySettings {
        var useBiometrics: Bool = true        // 使用生物识别
        var usePasscode: Bool = false        // 使用应用密码
        var autoLockTimeout: Int = 5         // 自动锁定时间(分钟)
        var encryptNotes: Bool = false        // 加密笔记
        var cloudKitEncryption: Bool = true  // iCloud 传输加密
    }
    
    // MARK: - Published 属性
    
    @Published var settings = SecuritySettings()
    @Published var isLocked: Bool = false
    @Published var authenticationError: String?
    
    // MARK: - 生物识别
    
    /// 生物识别类型
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
    }
    
    /// 获取支持的生物识别类型
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    /// 验证生物识别
    func authenticateWithBiometrics(reason: String = "解锁笔记") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            await MainActor.run {
                authenticationError = "生物识别不可用"
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                isLocked = !success
                authenticationError = nil
            }
            
            return success
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLocked = true
            }
            return false
        }
    }
    
    /// 验证密码
    func authenticateWithPasscode(_ passcode: String) -> Bool {
        // 简化实现 - 实际应该使用 Keychain 存储哈希值
        let storedPasscode = UserDefaults.standard.string(forKey: "appPasscode") ?? ""
        
        if storedPasscode.isEmpty {
            return true // 没有设置密码
        }
        
        let success = passcode == storedPasscode
        if success {
            isLocked = false
        }
        return success
    }
    
    /// 设置应用密码
    func setPasscode(_ passcode: String) {
        // 实际应该存储哈希值
        UserDefaults.standard.set(passcode, forKey: "appPasscode")
        settings.usePasscode = true
    }
    
    /// 移除密码
    func removePasscode() {
        UserDefaults.standard.removeObject(forKey: "appPasscode")
        settings.usePasscode = false
    }
    
    /// 锁定应用
    func lock() {
        isLocked = true
    }
    
    /// 解锁应用
    func unlock() {
        isLocked = false
    }
}

// MARK: - 数据加密

/// 数据加密工具
final class DataEncryption {
    
    /// 加密数据
    static func encrypt(_ data: Data, with key: Data) -> Data? {
        // 简化实现 - 实际应该使用 CryptoKit
        return data
    }
    
    /// 解密数据
    static func decrypt(_ data: Data, with key: Data) -> Data? {
        // 简化实现 - 实际应该使用 CryptoKit
        return data
    }
    
    /// 从密码生成密钥
    static func generateKey(from password: String) -> Data {
        // 简化实现 - 实际应该使用 PBKDF2
        return Data(password.utf8)
    }
}

// MARK: - 安全设置视图

import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var securityManager: SecurityManager
    @State private var showingPasscodeSetup = false
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    
    var body: some View {
        Form {
            Section("解锁方式") {
                Toggle("使用生物识别", isOn: $securityManager.settings.useBiometrics)
                    .disabled(securityManager.biometricType == .none)
                
                if securityManager.biometricType != .none {
                    HStack {
                        Text("生物识别类型")
                        Spacer()
                        Text(biometricName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("使用应用密码", isOn: $securityManager.settings.usePasscode)
                
                if securityManager.settings.usePasscode {
                    Button("更改密码") {
                        showingPasscodeSetup = true
                    }
                    
                    Button("移除密码", role: .destructive) {
                        securityManager.removePasscode()
                    }
                }
            }
            
            Section("自动锁定") {
                Picker("自动锁定时间", selection: $securityManager.settings.autoLockTimeout) {
                    Text("1 分钟").tag(1)
                    Text("5 分钟").tag(5)
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("从不").tag(0)
                }
            }
            
            Section("数据安全") {
                Toggle("加密笔记", isOn: $securityManager.settings.encryptNotes)
                
                Toggle("iCloud 传输加密", isOn: $securityManager.settings.cloudKitEncryption)
            }
            
            Section {
                Button("立即锁定") {
                    securityManager.lock()
                }
            }
        }
        .sheet(isPresented: $showingPasscodeSetup) {
            PasscodeSetupView(securityManager: securityManager) {
                showingPasscodeSetup = false
            }
        }
    }
    
    private var biometricName: String {
        switch securityManager.biometricType {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        case .none: return "无"
        }
    }
}

struct PasscodeSetupView: View {
    @ObservedObject var securityManager: SecurityManager
    let onComplete: () -> Void
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                SecureField("输入密码", text: $passcode)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                SecureField("确认密码", text: $confirmPasscode)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("确认") {
                    if passcode == confirmPasscode && passcode.count >= 4 {
                        securityManager.setPasscode(passcode)
                        onComplete()
                    } else {
                        errorMessage = "密码不匹配或太短"
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("设置密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onComplete()
                    }
                }
            }
        }
    }
}
