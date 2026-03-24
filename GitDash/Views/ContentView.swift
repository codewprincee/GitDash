import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var auth
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch auth.state {
            case .authenticated:
                MainView()
            default:
                LoginView()
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}

struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthenticationManager.self) private var auth

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            switch appState.selectedSection {
            case .dashboard:
                DashboardView()
            case .pullRequests:
                PRListView()
            case .actions:
                ActionsListView()
            case .issues:
                IssueListView()
            case .notifications:
                NotificationsListView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showCommandPalette.toggle() }) {
                    Label("Command Palette", systemImage: "command")
                }
                .help("⌘K")
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .sheet(isPresented: $state.showCommandPalette) {
            CommandPaletteView()
        }
    }
}
