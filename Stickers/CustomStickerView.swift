import SwiftUI
import PencilKit

/// 创建自定义贴纸视图
struct CreateStickerView: View {
    @ObservedObject var stickerManager: CustomStickerManager
    @Environment(\.dismiss) var dismiss
    
    let drawing: PKDrawing
    @State private var stickerName: String = ""
    @State private var selectedCategory: String = "自定义"
    @State private var newCategory: String = ""
    @State private var showingNewCategory: Bool = false
    @State private var previewImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 预览
                VStack(spacing: 12) {
                    Text("贴纸预览")
                        .font(.headline)
                    
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(height: 150)
                            .cornerRadius(12)
                            .overlay(
                                Text("无法生成预览")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .padding()
                
                // 名称输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("贴纸名称")
                        .font(.headline)
                    
                    TextField("输入贴纸名称", text: $stickerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 分类选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("分类")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(stickerManager.categories(), id: \.self) { category in
                                CategoryChip(
                                    name: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                            
                            // 新建分类
                            Button(action: { showingNewCategory = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("新建")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 保存按钮
                Button(action: saveSticker) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存为贴纸")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(stickerName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(stickerName.isEmpty)
            }
            .padding()
            .navigationTitle("创建贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewCategory) {
                newCategorySheet
            }
            .onAppear {
                generatePreview()
            }
        }
    }
    
    // MARK: - 新建分类表单
    
    private var newCategorySheet: View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("输入分类名称", text: $newCategory)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button(action: addNewCategory) {
                    Text("创建")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("新建分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        newCategory = ""
                        showingNewCategory = false
                    }
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func generatePreview() {
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        previewImage = image
    }
    
    private func addNewCategory() {
        if !newCategory.isEmpty && !stickerManager.categories().contains(newCategory) {
            selectedCategory = newCategory
            newCategory = ""
            showingNewCategory = false
        }
    }
    
    private func saveSticker() {
        if let sticker = stickerManager.createSticker(from: drawing, name: stickerName, category: selectedCategory) {
            stickerManager.saveSticker(sticker)
            dismiss()
        }
    }
}

// MARK: - 分类标签

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - 自定义贴纸板

struct CustomStickerBoardView: View {
    @ObservedObject var stickerManager: CustomStickerManager
    let onSelect: (Data) -> Void
    
    @State private var selectedCategory: String = "自定义"
    
    var body: some View {
        VStack(spacing: 16) {
            // 分类标签
            if !stickerManager.categories().isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stickerManager.categories(), id: \.self) { category in
                            CategoryChip(
                                name: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 贴纸网格
            if stickerManager.customStickers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无自定义贴纸")
                        .foregroundColor(.secondary)
                    Text("在笔记中绘制图案，可以保存为贴纸")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let stickers = stickerManager.stickers(in: selectedCategory)
                
                if stickers.isEmpty {
                    Text("该分类暂无贴纸")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70))
                        ], spacing: 12) {
                            ForEach(stickers) { sticker in
                                CustomStickerCell(sticker: sticker) {
                                    onSelect(sticker.imageData)
                                }
                                .contextMenu {
                                    Button("重命名") {
                                        // 重命名
                                    }
                                    Button("删除", role: .destructive) {
                                        stickerManager.deleteSticker(sticker)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - 贴纸单元格

struct CustomStickerCell: View {
    let sticker: CustomStickerManager.CustomSticker
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if let data = sticker.thumbnailData ?? sticker.imageData.data(using: .utf8),
               let uiImage = UIImage(data: sticker.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Image(systemName: "square.on.square")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
                    .frame(width: 60, height: 60)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}
