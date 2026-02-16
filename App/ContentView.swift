import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notebookVM: NotebookViewModel
    
    var body: some View {
        NavigationSplitView {
            NotebookListView()
        } detail: {
            if let selectedNotebook = notebookVM.selectedNotebook {
                NotebookDetailView(notebook: selectedNotebook)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "note.text")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("选择一个笔记本开始")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
