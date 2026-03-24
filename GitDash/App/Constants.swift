import Foundation

enum AppConstants {
    // GitHub OAuth App — Users need to create their own at https://github.com/settings/developers
    // For development, use the Device Flow (no redirect URI needed)
    static var clientID: String {
        // Check for environment override first, then use default
        ProcessInfo.processInfo.environment["GITDASH_CLIENT_ID"] ?? "Ov23li0000000000000" // Replace with your OAuth App Client ID
    }

    static let githubAPIBase = "https://api.github.com"
    static let githubGraphQLEndpoint = "https://api.github.com/graphql"
    static let githubDeviceCodeURL = "https://github.com/login/device/code"
    static let githubTokenURL = "https://github.com/login/oauth/access_token"
    static let githubDeviceVerificationURL = "https://github.com/login/device"

    static let oauthScopes = "repo read:org notifications read:user workflow"

    static let keychainService = "com.gitdash.app"
    static let keychainTokenKey = "github_access_token"

    // Polling intervals (seconds)
    static let dashboardPollInterval: TimeInterval = 120
    static let notificationPollInterval: TimeInterval = 60
    static let actionsPollInterval: TimeInterval = 30
    static let prPollInterval: TimeInterval = 90
}
