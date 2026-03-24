import SwiftUI

@Observable
final class AppState {
    var selectedSection: SidebarSection = .dashboard
    var selectedRepo: String?  // "owner/repo"
    var showCommandPalette = false

    enum SidebarSection: String, CaseIterable, Identifiable {
        case dashboard
        case pullRequests
        case actions
        case issues
        case notifications
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .pullRequests: return "Pull Requests"
            case .actions: return "Actions"
            case .issues: return "Issues"
            case .notifications: return "Notifications"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .pullRequests: return "arrow.triangle.branch"
            case .actions: return "gearshape.2"
            case .issues: return "exclamationmark.circle"
            case .notifications: return "bell"
            case .settings: return "gear"
            }
        }
    }
}
