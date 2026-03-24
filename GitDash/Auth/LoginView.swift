import SwiftUI

struct LoginView: View {
    @Environment(AuthenticationManager.self) private var auth

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App logo
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("GitDash")
                .font(.largeTitle.bold())

            Text("Your GitHub dashboard.\nAll repos, PRs, CI, issues — in one window.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            switch auth.state {
            case .loading:
                ProgressView("Loading...")

            case .unauthenticated:
                Button(action: { Task { await auth.startDeviceFlow() } }) {
                    HStack {
                        Image(systemName: "person.badge.key")
                        Text("Sign in with GitHub")
                    }
                    .frame(width: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            case .awaitingUserCode(let code, let uri):
                deviceCodeView(code: code, uri: uri)

            case .polling:
                ProgressView("Waiting for authorization...")

            case .error(let message):
                errorView(message: message)

            case .authenticated:
                ProgressView("Loading your data...")
            }

            Spacer()
        }
        .frame(width: 480, height: 500)
        .padding(40)
    }

    private func deviceCodeView(code: String, uri: String) -> some View {
        VStack(spacing: 16) {
            Text("Enter this code on GitHub:")
                .font(.headline)

            // User code — big and prominent
            Text(code)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .tracking(4)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                )
                .textSelection(.enabled)

            Button("Open GitHub") {
                if let url = URL(string: uri) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Waiting for you to authorize...")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView()
                .controlSize(.small)

            Button("Cancel") { auth.cancelFlow() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await auth.startDeviceFlow() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
