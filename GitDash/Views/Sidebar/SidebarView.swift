import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthenticationManager.self) private var auth
    @State private var notifService = NotificationService()

    var body: some View {
        @Bindable var state = appState

        List(selection: $state.selectedSection) {
            Section("GitHub") {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(AppState.SidebarSection.dashboard)

                Label {
                    HStack {
                        Text("Pull Requests")
                        Spacer()
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.branch")
                }
                .tag(AppState.SidebarSection.pullRequests)

                Label("Actions", systemImage: "gearshape.2")
                    .tag(AppState.SidebarSection.actions)

                Label("Issues", systemImage: "exclamationmark.circle")
                    .tag(AppState.SidebarSection.issues)

                Label {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        if notifService.unreadCount > 0 {
                            Text("\(notifService.unreadCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red, in: Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: "bell")
                }
                .tag(AppState.SidebarSection.notifications)
            }

            Section {
                Label("Settings", systemImage: "gear")
                    .tag(AppState.SidebarSection.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            if let user = auth.currentUser {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(.quaternary)
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 0) {
                        Text(user.name ?? user.login).font(.caption.bold()).lineLimit(1)
                        Text("@\(user.login)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .task {
            await notifService.fetchNotifications()
        }
    }
}
