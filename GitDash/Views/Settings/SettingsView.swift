import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var auth

    var body: some View {
        Form {
            if let user = auth.currentUser {
                Section("Account") {
                    HStack {
                        AvatarView(url: user.avatarUrl, size: 40)
                        VStack(alignment: .leading) {
                            Text(user.name ?? user.login).font(.headline)
                            Text("@\(user.login)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("GitDash")
                    Spacer()
                    Text("v1.0.0").foregroundStyle(.secondary)
                }
                HStack {
                    Text("GitHub")
                    Spacer()
                    Link("codewprincee/GitDash", destination: URL(string: "https://github.com/codewprincee/GitDash")!)
                        .font(.caption)
                }
            }

            Section("Danger Zone") {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.logout() }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
