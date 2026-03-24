import Foundation

@Observable
final class NotificationService {
    var notifications: [GitHubNotification] = []
    var isLoading = false
    var error: String?

    var unreadCount: Int { notifications.filter(\.unread).count }

    func fetchNotifications() async {
        isLoading = true
        error = nil
        do {
            let result: [GitHubNotification] = try await GitHubAPIClient.shared.get(
                "/notifications",
                queryItems: [URLQueryItem(name: "per_page", value: "50")]
            )
            await MainActor.run {
                notifications = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    func markAsRead(threadID: String) async throws {
        try await GitHubAPIClient.shared.patch(
            "/notifications/threads/\(threadID)",
            body: nil
        ) as EmptyResponse
        await MainActor.run {
            if let idx = notifications.firstIndex(where: { $0.id == threadID }) {
                // Can't mutate struct directly, refetch
            }
        }
        await fetchNotifications()
    }

    func markAllRead() async throws {
        let _: EmptyResponse = try await GitHubAPIClient.shared.put(
            "/notifications",
            body: ["read": true]
        )
        await fetchNotifications()
    }
}
