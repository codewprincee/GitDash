import Foundation

@Observable
final class AuthenticationManager {
    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case awaitingUserCode(userCode: String, verificationURI: String)
        case polling
        case authenticated
        case error(String)

        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.unauthenticated, .unauthenticated),
                 (.polling, .polling), (.authenticated, .authenticated):
                return true
            case (.awaitingUserCode(let a, _), .awaitingUserCode(let b, _)):
                return a == b
            case (.error(let a), .error(let b)):
                return a == b
            default: return false
            }
        }
    }

    var state: AuthState = .loading
    var currentUser: GitHubUser?
    private var pollTask: Task<Void, Never>?

    // MARK: - Restore Session

    func restoreSession() async {
        guard let token = KeychainManager.getToken() else {
            state = .unauthenticated
            return
        }

        await GitHubAPIClient.shared.setToken(token)

        do {
            let user: GitHubUser = try await GitHubAPIClient.shared.get("/user")
            currentUser = user
            state = .authenticated
        } catch {
            // Token expired or invalid
            KeychainManager.delete()
            await GitHubAPIClient.shared.clearToken()
            state = .unauthenticated
        }
    }

    // MARK: - Device Flow

    func startDeviceFlow() async {
        state = .loading

        guard let url = URL(string: AppConstants.githubDeviceCodeURL) else {
            state = .error("Invalid device code URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": AppConstants.clientID,
            "scope": AppConstants.oauthScopes
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                state = .error("Failed to start device flow")
                return
            }

            let deviceResponse = try JSONDecoder().decode(DeviceCodeResponse.self, from: data)

            state = .awaitingUserCode(
                userCode: deviceResponse.userCode,
                verificationURI: deviceResponse.verificationUri
            )

            // Start polling for token
            pollForToken(
                deviceCode: deviceResponse.deviceCode,
                interval: deviceResponse.interval
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func pollForToken(deviceCode: String, interval: Int) {
        pollTask?.cancel()
        pollTask = Task {
            var currentInterval = interval

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(currentInterval))
                if Task.isCancelled { break }

                guard let url = URL(string: AppConstants.githubTokenURL) else { break }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: String] = [
                    "client_id": AppConstants.clientID,
                    "device_code": deviceCode,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (data, _) = try await URLSession.shared.data(for: request)

                    // Try to decode as success
                    if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data),
                       let token = tokenResponse.accessToken {
                        // Success!
                        let saved = KeychainManager.save(token: token)
                        if !saved {
                            await MainActor.run { state = .error("Failed to save token to Keychain") }
                            return
                        }

                        await GitHubAPIClient.shared.setToken(token)

                        // Fetch user profile
                        let user: GitHubUser = try await GitHubAPIClient.shared.get("/user")
                        await MainActor.run {
                            currentUser = user
                            state = .authenticated
                        }
                        return
                    }

                    // Check for error
                    if let errorResponse = try? JSONDecoder().decode(DeviceFlowError.self, from: data) {
                        switch errorResponse.error {
                        case "authorization_pending":
                            continue // Keep polling
                        case "slow_down":
                            currentInterval += 5
                            continue
                        case "expired_token":
                            await MainActor.run { state = .error("Code expired. Please try again.") }
                            return
                        case "access_denied":
                            await MainActor.run { state = .error("Access denied. You cancelled the authorization.") }
                            return
                        default:
                            await MainActor.run { state = .error(errorResponse.errorDescription ?? "Unknown error") }
                            return
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        await MainActor.run { state = .error(error.localizedDescription) }
                    }
                    return
                }
            }
        }
    }

    // MARK: - Logout

    func logout() async {
        pollTask?.cancel()
        KeychainManager.delete()
        await GitHubAPIClient.shared.clearToken()
        currentUser = nil
        state = .unauthenticated
    }

    func cancelFlow() {
        pollTask?.cancel()
        state = .unauthenticated
    }
}

// MARK: - Response Models

struct DeviceCodeResponse: Decodable {
    let deviceCode: String
    let userCode: String
    let verificationUri: String
    let expiresIn: Int
    let interval: Int

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

struct TokenResponse: Decodable {
    let accessToken: String?
    let tokenType: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}

struct DeviceFlowError: Decodable {
    let error: String
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}
