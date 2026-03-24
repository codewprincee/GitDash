import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var auth
    @AppStorage("dashboardPollInterval") private var dashboardInterval: Double = 120
    @AppStorage("notificationPollInterval") private var notifInterval: Double = 60
    @AppStorage("actionsPollInterval") private var actionsInterval: Double = 30
    @AppStorage("defaultClonePath") private var clonePath: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account
                if let user = auth.currentUser {
                    GroupBox("Account") {
                        HStack(spacing: 12) {
                            AvatarView(url: user.avatarUrl, size: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name ?? user.login).font(.headline)
                                Text("@\(user.login)").font(.caption).foregroundStyle(.secondary)
                                if let bio = user.bio {
                                    Text(bio).font(.caption).foregroundStyle(.tertiary).lineLimit(2)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(user.publicRepos ?? 0) repos").font(.caption).foregroundStyle(.secondary)
                                Text("\(user.followers ?? 0) followers").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Polling
                GroupBox("Polling Intervals") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Dashboard")
                            Slider(value: $dashboardInterval, in: 30...600, step: 30)
                            Text("\(Int(dashboardInterval))s").monospacedDigit().frame(width: 40)
                        }
                        HStack {
                            Text("Notifications")
                            Slider(value: $notifInterval, in: 15...300, step: 15)
                            Text("\(Int(notifInterval))s").monospacedDigit().frame(width: 40)
                        }
                        HStack {
                            Text("Actions/CI")
                            Slider(value: $actionsInterval, in: 10...120, step: 10)
                            Text("\(Int(actionsInterval))s").monospacedDigit().frame(width: 40)
                        }
                        Text("Lower values = more API calls. GitHub allows 5000/hour.")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }

                // Git
                GroupBox("Git") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default clone path")
                            Spacer()
                            Text(clonePath.isEmpty ? "Not set" : clonePath)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Button("Choose") {
                                let panel = NSOpenPanel()
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                panel.begin { response in
                                    if response == .OK, let url = panel.url {
                                        clonePath = url.path
                                    }
                                }
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Keyboard shortcuts reference
                GroupBox("Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: 6) {
                        shortcutRow("⌘K", "Command Palette")
                        shortcutRow("⌘1", "Dashboard")
                        shortcutRow("⌘2", "Pull Requests")
                        shortcutRow("⌘3", "Actions")
                        shortcutRow("⌘4", "Issues")
                        shortcutRow("⌘5", "Notifications")
                    }
                    .padding(.vertical, 4)
                }

                // About
                GroupBox("About") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("GitDash"); Spacer(); Text("v1.0.0").foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Source"); Spacer()
                            Link("github.com/codewprincee/GitDash", destination: URL(string: "https://github.com/codewprincee/GitDash")!)
                                .font(.caption)
                        }
                        HStack {
                            Text("License"); Spacer(); Text("MIT").foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Sign out
                GroupBox("Danger Zone") {
                    Button("Sign Out", role: .destructive) {
                        Task { await auth.logout() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            Text(action).font(.caption)
            Spacer()
        }
    }
}
