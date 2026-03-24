import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthenticationManager.self) private var auth

    var body: some View {
        @Bindable var state = appState

        List(selection: $state.selectedSection) {
            Section("GitHub") {
                ForEach(AppState.SidebarSection.allCases.filter { $0 != .settings }) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
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

                    Text(user.login)
                        .font(.caption.bold())
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }
}
