//
//  PerformanceConfig.swift
//  ClawNotes
//
//  性能优化配置
//

import Foundation

/// 性能配置
struct PerformanceConfig {
    
    // MARK: - 缓存配置
    
    /// 内存缓存大小 (MB)
    static let memoryCacheSize: Int = 100
    
    /// 磁盘缓存大小 (MB)
    static let diskCacheSize: Int = 500
    
    /// 缓存过期时间 (秒)
    static let cacheExpirationTime: TimeInterval = 3600
    
    // MARK: - 图像配置
    
    /// 缩略图尺寸
    static let thumbnailSize = CGSize(width: 200, height: 280)
    
    /// 预览图尺寸
    static let previewSize = CGSize(width: 612, height: 792)
    
    /// 导出图质量
    static let exportImageQuality: CGFloat = 1.0
    
    // MARK: - 同步配置
    
    /// 自动同步间隔 (秒)
    static let syncInterval: TimeInterval = 300
    
    /// 最大重试次数
    static let maxRetryCount = 3
    
    /// 重试延迟 (秒)
    static let retryDelay: TimeInterval = 5
    
    // MARK: - 性能限制
    
    /// 最大同时打开的笔记本
    static let maxOpenNotebooks: Int = 10
    
    /// 每页最大笔画数
    static let maxStrokesPerPage: Int = 10000
    
    /// 最大撤销栈深度
    static let maxUndoStackDepth: Int = 50
    
    // MARK: - UI 配置
    
    /// 页面切换动画时长
    static let pageAnimationDuration: TimeInterval = 0.3
    
    /// 手势识别阈值
    static let gestureThreshold: CGFloat = 50
    
    // MARK: - 调试模式
    
    #if DEBUG
    static let isDebug = true
    static let logLevel = LogLevel.verbose
    #else
    static let isDebug = false
    static let logLevel = LogLevel.error
    #endif
}

/// 日志级别
enum LogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    
    var prefix: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

/// 日志工具
final class Logger {
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        guard level.rawValue >= PerformanceConfig.logLevel.rawValue else { return }
        
        let fileName = (file as NSString).lastPathComponent
        print("\(level.prefix) [\(fileName):\(line)] \(function)")
        print("   \(message)")
        #endif
    }
    
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

/// 性能追踪
final class PerformanceTracker {
    
    static let shared = PerformanceTracker()
    
    private var measurements: [String: [TimeInterval]] = [:]
    
    private init() {}
    
    /// 开始计时
    func startMeasurement(_ identifier: String) {
        measurements[identifier] = []
    }
    
    /// 结束计时
    func endMeasurement(_ identifier: String) -> TimeInterval? {
        return nil // 简化实现
    }
    
    /// 获取平均时间
    func averageTime(_ identifier: String) -> TimeInterval? {
        guard let times = measurements[identifier], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    /// 清空测量数据
    func clear() {
        measurements.removeAll()
    }
}
