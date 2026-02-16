import Foundation

/// 性能监控管理器
/// 监控应用性能指标
final class PerformanceMonitor: ObservableObject {
    
    // MARK: - 性能指标
    
    struct PerformanceMetrics {
        var memoryUsage: UInt64 = 0
        var cpuUsage: Double = 0.0
        var fps: Double = 0.0
        var pageLoadTime: TimeInterval = 0.0
        var saveTime: TimeInterval = 0.0
    }
    
    // MARK: - Published 属性
    
    @Published var metrics = PerformanceMetrics()
    @Published var isMonitoring: Bool = false
    
    // MARK: - 私有属性
    
    private var timer: Timer?
    
    // MARK: - 监控
    
    /// 开始监控
    func startMonitoring() {
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    /// 停止监控
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    /// 更新指标
    private func updateMetrics() {
        // 内存使用
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            metrics.memoryUsage = info.resident_size
        }
    }
    
    /// 记录页面加载时间
    func recordPageLoadTime(_ time: TimeInterval) {
        metrics.pageLoadTime = time
    }
    
    /// 记录保存时间
    func recordSaveTime(_ time: TimeInterval) {
        metrics.saveTime = time
    }
    
    // MARK: - 优化建议
    
    /// 获取优化建议
    var optimizationTips: [String] {
        var tips: [String] = []
        
        // 内存检查
        let memoryMB = metrics.memoryUsage / 1024 / 1024
        if memoryMB > 500 {
            tips.append("内存使用较高 (\(memoryMB)MB)，建议减少打开的笔记本数量")
        }
        
        // 保存时间检查
        if metrics.saveTime > 2.0 {
            tips.append("保存时间较长 (\(String(format: "%.1f", metrics.saveTime))s)，建议减少页面内容")
        }
        
        return tips
    }
}

// MARK: - 内存优化

/// 内存优化管理器
final class MemoryOptimizer {
    
    /// 清理缓存
    static func clearCache() {
        // 清理图片缓存
        URLCache.shared.removeAllCachedResponses()
        
        // 清理临时文件
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempDir)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    /// 获取当前内存使用
    static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}

// MARK: - 性能报告

import SwiftUI

struct PerformanceReportView: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        Form {
            Section("当前状态") {
                HStack {
                    Text("内存使用")
                    Spacer()
                    Text(formatBytes(monitor.metrics.memoryUsage))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("页面加载")
                    Spacer()
                    Text("\(String(format: "%.2f", monitor.metrics.pageLoadTime * 1000))ms")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("保存时间")
                    Spacer()
                    Text("\(String(format: "%.1f", monitor.metrics.saveTime))s")
                        .foregroundColor(.secondary)
                }
            }
            
            if !monitor.optimizationTips.isEmpty {
                Section("优化建议") {
                    ForEach(monitor.optimizationTips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb")
                            .font(.callout)
                    }
                }
            }
            
            Section {
                Button("清理缓存") {
                    MemoryOptimizer.clearCache()
                }
                
                Button(monitor.isMonitoring ? "停止监控" : "开始监控") {
                    if monitor.isMonitoring {
                        monitor.stopMonitoring()
                    } else {
                        monitor.startMonitoring()
                    }
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1024 / 1024
        return String(format: "%.1f MB", mb)
    }
}
