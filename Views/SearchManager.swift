import Foundation
import PencilKit

/// 搜索管理器
/// 支持按标题搜索和内容搜索
final class SearchManager: ObservableObject {
    
    /// 搜索结果
    struct SearchResult: Identifiable {
        let id = UUID()
        let type: ResultType
        let title: String
        let preview: String?
        let notebookId: UUID
        let pageIndex: Int?
        
        enum ResultType {
            case notebook
            case page
        }
    }
    
    /// 搜索范围
    enum SearchScope {
        case all
        case currentNotebook
    }
    
    /// 搜索状态
    enum SearchState {
        case idle
        case searching
        case noResults
        case results([SearchResult])
    }
    
    // MARK: - Published 属性
    
    @Published var searchText: String = ""
    @Published var state: SearchState = .idle
    @Published var scope: SearchScope = .all
    
    // MARK: - 搜索方法
    
    /// 搜索笔记本和页面
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - notebooks: 笔记本列表
    ///   - scope: 搜索范围
    func search(query: String, in notebooks: [Notebook], scope: SearchScope = .all) {
        guard !query.isEmpty else {
            state = .idle
            return
        }
        
        state = .searching
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var results: [SearchResult] = []
            let lowercasedQuery = query.lowercased()
            
            let notebooksToSearch: [Notebook]
            switch scope {
            case .all:
                notebooksToSearch = notebooks
            case .currentNotebook:
                // 需要传入当前笔记本
                notebooksToSearch = []
            }
            
            for notebook in notebooksToSearch {
                // 搜索笔记本标题
                if notebook.title.lowercased().contains(lowercasedQuery) {
                    results.append(SearchResult(
                        type: .notebook,
                        title: notebook.title,
                        preview: nil,
                        notebookId: notebook.id,
                        pageIndex: nil
                    ))
                }
                
                // 搜索页面内容 (如果需要)
                for (index, page) in notebook.pages.enumerated() {
                    // 这里可以添加更多搜索逻辑
                    // 例如：OCR 识别手写文字
                    if let _ = page.drawingData {
                        // 有内容的页面
                        results.append(SearchResult(
                            type: .page,
                            title: "\(notebook.title) - 第 \(index + 1) 页",
                            preview: nil,
                            notebookId: notebook.id,
                            pageIndex: index
                        ))
                    }
                }
            }
            
            DispatchQueue.main.async {
                if results.isEmpty {
                    self?.state = .noResults
                } else {
                    self?.state = .results(results)
                }
            }
        }
    }
    
    /// 清除搜索
    func clearSearch() {
        searchText = ""
        state = .idle
    }
}

// MARK: - 搜索视图组件

import SwiftUI

/// 搜索栏视图
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索"
    var onSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.search)
                .onSubmit {
                    onSearch()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

/// 搜索结果视图
struct SearchResultsView: View {
    let results: [SearchManager.SearchResult]
    var onSelect: (SearchManager.SearchResult) -> Void
    
    var body: some View {
        List(results) { result in
            Button(action: { onSelect(result) }) {
                HStack(spacing: 12) {
                    Image(systemName: result.type == .notebook ? "book.closed.fill" : "doc.text.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let preview = result.preview {
                            Text(preview)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
}
