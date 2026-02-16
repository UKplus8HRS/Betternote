import SwiftUI

@main
struct ClawNotesApp: App {
    @StateObject private var notebookVM = NotebookViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notebookVM)
        }
    }
}
