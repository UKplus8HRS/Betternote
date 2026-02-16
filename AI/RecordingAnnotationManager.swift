import Foundation
import AVFoundation
import PencilKit

/// 录音标注管理器
/// 录音时可以在任意位置添加文字/绘图标注
final class RecordingAnnotationManager: NSObject, ObservableObject {
    
    // MARK: - 录音状态
    
    enum RecordingState {
        case idle
        case recording
        case paused
        case stopped
    }
    
    // MARK: - Published 属性
    
    @Published var state: RecordingState = .idle
    @Published var currentTime: TimeInterval = 0
    @Published var session: RecordingSession
    @Published var audioLevel: Float = 0  // 音量级别 (0-1)
    
    // MARK: - 私有属性
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingURL: URL?
    
    // MARK: - 初始化
    
    override init() {
        self.session = RecordingSession()
        super.init()
    }
    
    // MARK: - 录音控制
    
    /// 开始录音
    func startRecording() throws {
        // 配置音频会话
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)
        
        // 创建录音文件
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        // 配置录音器
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        // 开始计时
        state = .recording
        startTimer()
        
        // 初始化录音会话
        self.session = RecordingSession()
        self.session.audioURL = recordingURL
    }
    
    /// 暂停录音
    func pauseRecording() {
        audioRecorder?.pause()
        state = .paused
        stopTimer()
    }
    
    /// 继续录音
    func resumeRecording() {
        audioRecorder?.record()
        state = .recording
        startTimer()
    }
    
    /// 停止录音
    func stopRecording() {
        audioRecorder?.stop()
        state = .stopped
        stopTimer()
        
        // 获取录音时长
        if let url = recordingURL {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                session.duration = player.duration
            } catch {
                print("获取录音时长失败: \(error)")
            }
        }
    }
    
    /// 添加文字标注
    func addTextAnnotation(_ text: String) {
        session.addAnnotation(at: currentTime, text: text)
    }
    
    /// 添加绘图标注
    func addDrawingAnnotation(_ drawing: PKDrawing) {
        let data = drawing.dataRepresentation()
        session.addAnnotation(at: currentTime, text: "[绘图]", drawing: data)
    }
    
    // MARK: - 播放控制
    
    /// 播放录音
    func play() throws {
        guard let url = session.audioURL else { return }
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
        
        // 开始计时
        startPlaybackTimer()
    }
    
    /// 播放到指定时间
    func play(from timestamp: TimeInterval) throws {
        guard let url = session.audioURL else { return }
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.currentTime = timestamp
        audioPlayer?.play()
        
        startPlaybackTimer()
    }
    
    /// 暂停播放
    func pausePlayback() {
        audioPlayer?.pause()
        stopTimer()
    }
    
    /// 停止播放
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        stopTimer()
    }
    
    /// 跳转到指定时间
    func seek(to timestamp: TimeInterval) {
        currentTime = timestamp
        audioPlayer?.currentTime = timestamp
    }
    
    // MARK: - 计时器
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            // 转换分贝到 0-1 范围
            self.audioLevel = max(0, min(1, (power + 60) / 60))
            
            self.currentTime = recorder.currentTime
        }
    }
    
    private func startPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            
            self.currentTime = player.currentTime
            
            if !player.isPlaying {
                self.stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 清理
    
    func reset() {
        state = .idle
        currentTime = 0
        session = RecordingSession()
        audioRecorder = nil
        audioPlayer = nil
    }
}
