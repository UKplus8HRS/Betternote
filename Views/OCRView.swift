import SwiftUI
import PhotosUI

/// OCR 提取视图
/// 从图片/PDF 提取文字
struct OCRView: View {
    @ObservedObject var ocrManager: OCRManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker: Bool = false
    @State private var showingPDFPicker: Bool = false
    @State private var selectedLanguage: String = "zh-Hans"
    @State private var showingResult: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 图片预览
                imagePreview
                
                // 语言选择
                languageSelector
                
                // 操作按钮
                actionButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("文字识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                if let result = ocrManager.result {
                    OCRResultView(result: result, onUse: useText)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, onImageSelected: processImage)
            }
        }
    }
    
    // MARK: - 图片预览
    
    private var imagePreview: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("选择图片或 PDF 进行文字识别")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 语言选择
    
    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("识别语言")
                .font(.headline)
            
            Picker("语言", selection: $selectedLanguage) {
                ForEach(Array(OCRManager.supportedLanguages.keys.sorted()), id: \.self) { key in
                    Text(OCRManager.supportedLanguages[key] ?? key).tag(key)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - 操作按钮
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 选择图片
            Button(action: { showingImagePicker = true }) {
                HStack {
                    Image(systemName: "photo")
                    Text("选择图片")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // 选择 PDF
            Button(action: { showingPDFPicker = true }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("选择 PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // 开始识别
            if selectedImage != nil || showingPDFPicker {
                Button(action: startOCR) {
                    HStack {
                        if ocrManager.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(ocrManager.isProcessing ? "识别中..." : "开始识别")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ocrManager.isProcessing ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(ocrManager.isProcessing)
            }
            
            // 进度条
            if ocrManager.isProcessing {
                VStack(spacing: 4) {
                    ProgressView(value: ocrManager.progress)
                    Text("\(Int(ocrManager.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 错误提示
            if let error = ocrManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - 方法
    
    private func processImage(_ image: UIImage) {
        selectedImage = image
    }
    
    private func startOCR() {
        guard let image = selectedImage else { return }
        
        Task {
            let result = await ocrManager.recognizeText(from: image, language: selectedLanguage)
            
            if result != nil {
                showingResult = true
            }
        }
    }
    
    private func useText(_ text: String) {
        // 将识别的文字插入到笔记
        // 通过 Notification 或回调传递
        dismiss()
    }
}

// MARK: - OCR 结果视图

struct OCRResultView: View {
    let result: OCRManager.OCRResult
    let onUse: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var editedText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 置信度
                HStack {
                    Text("识别置信度")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(result.confidence * 100))%")
                        .foregroundColor(result.confidence > 0.8 ? .green : .orange)
                }
                
                Divider()
                
                // 识别结果
                VStack(alignment: .leading, spacing: 8) {
                    Text("识别结果")
                        .font(.headline)
                    
                    TextEditor(text: $editedText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button("复制") {
                        UIPasteboard.general.string = editedText
                    }
                    .buttonStyle(.bordered)
                    
                    Button("插入笔记") {
                        onUse(editedText)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                editedText = result.text
            }
        }
    }
}

// MARK: - 图片选择器

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.image = image
                        self.parent.onImageSelected(image)
                    }
                }
            }
        }
    }
}
