import SwiftUI

@main
struct GitDashApp: App {
    @State private var auth = AuthenticationManager()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("GitDash") {
                Button("Command Palette") {
                    appState.showCommandPalette.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()

                Button("Dashboard") { appState.selectedSection = .dashboard }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Pull Requests") { appState.selectedSection = .pullRequests }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Actions") { appState.selectedSection = .actions }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Issues") { appState.selectedSection = .issues }
                    .keyboardShortcut("4", modifiers: .command)
                Button("Notifications") { appState.selectedSection = .notifications }
                    .keyboardShortcut("5", modifiers: .command)
            }
        }
    }
}
