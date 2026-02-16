import SwiftUI

/// 模板市场视图
struct TemplateMarketplaceView: View {
    @ObservedObject var templateManager: TemplateManager
    @EnvironmentObject var notebookVM: NotebookViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText: String = ""
    @State private var selectedCategory: TemplateCategory?
    @State private var showingPreview: Bool = false
    @State private var selectedTemplate: NotebookTemplate?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                // 分类标签
                categoryTabs
                
                // 模板网格
                templateGrid
            }
            .navigationTitle("模板市场")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let template = selectedTemplate {
                    TemplatePreviewView(template: template) {
                        createNotebook(from: template)
                    }
                }
            }
        }
    }
    
    // MARK: - 搜索栏
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索模板", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - 分类标签
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部
                CategoryTabButton(
                    name: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(TemplateCategory.allCases, id: \.self) { category in
                    CategoryTabButton(
                        name: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - 模板网格
    
    private var templateGrid: some View {
        let filteredTemplates = getFilteredTemplates()
        
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredTemplates) { template in
                    TemplateCardView(template: template)
                        .onTapGesture {
                            selectedTemplate = template
                            showingPreview = true
                        }
                }
            }
            .padding()
        }
    }
    
    private func getFilteredTemplates() -> [NotebookTemplate] {
        var templates = templateManager.templates + templateManager.customTemplates
        
        // 分类筛选
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            templates = templates.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        return templates
    }
    
    private func createNotebook(from template: NotebookTemplate) {
        let notebook = templateManager.createNotebook(from: template)
        notebookVM.notebooks.insert(notebook, at: 0)
        notebookVM.selectNotebook(notebook)
        notebookVM.saveNotebooks()
        dismiss()
    }
}

// MARK: - 分类标签按钮

struct CategoryTabButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - 模板卡片

struct TemplateCardView: View {
    let template: NotebookTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: template.coverColor) ?? .blue)
                    .frame(height: 100)
                
                // 页面预览
                VStack(spacing: 2) {
                    ForEach(template.pages.prefix(3), id: \.self) { page in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)
                            .padding(.horizontal, 12)
                    }
                }
            }
            
            // 名称和描述
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 标签
                HStack(spacing: 4) {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 模板预览视图

struct TemplatePreviewView: View {
    let template: NotebookTemplate
    let onUse: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 封面
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: template.coverColor) ?? .blue)
                            .frame(height: 200)
                        
                        VStack {
                            Image(systemName: template.category.icon)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text(template.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("简介")
                            .font(.headline)
                        Text(template.description)
                            .foregroundColor(.secondary)
                    }
                    
                    // 页面预览
                    VStack(alignment: .leading, spacing: 8) {
                        Text("包含 \(template.pages.count) 页")
                            .font(.headline)
                        
                        ForEach(Array(template.pages.enumerated()), id: \.offset) { index, page in
                            HStack {
                                Text("第 \(index + 1) 页")
                                    .font(.subheadline)
                                Spacer()
                                Text(page.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    // 标签
                    if !template.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标签")
                                .font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(template.tags, id: \.self) { tag in
                                    Text(tag)
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
                    
                    // 使用按钮
                    Button(action: {
                        onUse()
                        dismiss()
                    }) {
                        Text("使用模板")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("模板预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + 8
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + 8
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
