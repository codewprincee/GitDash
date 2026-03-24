import SwiftUI

struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var query = ""

    private let commands: [(icon: String, title: String, section: AppState.SidebarSection?)] = [
        ("square.grid.2x2", "Go to Dashboard", .dashboard),
        ("arrow.triangle.branch", "Go to Pull Requests", .pullRequests),
        ("gearshape.2", "Go to Actions", .actions),
        ("exclamationmark.circle", "Go to Issues", .issues),
        ("bell", "Go to Notifications", .notifications),
        ("gear", "Go to Settings", .settings),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type a command...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { executeFirst() }

                Button("Esc") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredCommands, id: \.title) { cmd in
                        Button(action: { execute(cmd) }) {
                            HStack {
                                Image(systemName: cmd.icon)
                                    .frame(width: 20)
                                    .foregroundStyle(.secondary)
                                Text(cmd.title)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 500, height: 350)
    }

    private var filteredCommands: [(icon: String, title: String, section: AppState.SidebarSection?)] {
        if query.isEmpty { return commands }
        return commands.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private func execute(_ cmd: (icon: String, title: String, section: AppState.SidebarSection?)) {
        if let section = cmd.section {
            appState.selectedSection = section
        }
        dismiss()
    }

    private func executeFirst() {
        if let first = filteredCommands.first {
            execute(first)
        }
    }
}
