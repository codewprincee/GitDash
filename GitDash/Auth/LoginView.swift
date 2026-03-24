import SwiftUI

struct LoginView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var loginMethod: LoginMethod = .token
    @State private var tokenInput = ""

    enum LoginMethod {
        case token
        case deviceFlow
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

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

            case .unauthenticated, .error:
                if case .error(let msg) = auth.state {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                }

                Picker("Login Method", selection: $loginMethod) {
                    Text("Personal Access Token").tag(LoginMethod.token)
                    Text("GitHub Device Flow").tag(LoginMethod.deviceFlow)
                }
                .pickerStyle(.segmented)
                .frame(width: 360)

                if loginMethod == .token {
                    tokenLoginView
                } else {
                    deviceFlowButton
                }

            case .awaitingUserCode(let code, let uri):
                deviceCodeView(code: code, uri: uri)

            case .polling:
                ProgressView("Waiting for authorization...")

            case .authenticated:
                ProgressView("Loading your data...")
            }

            Spacer()
        }
        .frame(width: 500, height: 560)
        .padding(40)
    }

    // MARK: - Token Login

    private var tokenLoginView: some View {
        VStack(spacing: 12) {
            Text("Paste a GitHub Personal Access Token")
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField("ghp_xxxx... or gho_xxxx...", text: $tokenInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)

            Button(action: { Task { await auth.loginWithToken(tokenInput) } }) {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Sign In")
                }
                .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty)

            Text("Get a token at [github.com/settings/tokens](https://github.com/settings/tokens)\nOr run: `gh auth token` in terminal")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Device Flow

    private var deviceFlowButton: some View {
        VStack(spacing: 8) {
            Button(action: { Task { await auth.startDeviceFlow() } }) {
                HStack {
                    Image(systemName: "person.badge.key")
                    Text("Sign in with GitHub")
                }
                .frame(width: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Requires a GitHub OAuth App Client ID in Constants.swift")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func deviceCodeView(code: String, uri: String) -> some View {
        VStack(spacing: 16) {
            Text("Enter this code on GitHub:")
                .font(.headline)

            Text(code)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .tracking(4)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary))
                .textSelection(.enabled)

            Button("Open GitHub") {
                if let url = URL(string: uri) { NSWorkspace.shared.open(url) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            ProgressView()
                .controlSize(.small)
            Text("Waiting for you to authorize...")
                .font(.caption).foregroundStyle(.secondary)

            Button("Cancel") { auth.cancelFlow() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
