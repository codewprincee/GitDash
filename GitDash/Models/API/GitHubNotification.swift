import Foundation

struct GitHubNotification: Codable, Identifiable {
    let id: String
    let unread: Bool
    let reason: String
    let updatedAt: String
    let subject: NotificationSubject
    let repository: NotificationRepo

    struct NotificationSubject: Codable {
        let title: String
        let type: String  // PullRequest, Issue, Release, Discussion
        let url: String?
    }

    struct NotificationRepo: Codable {
        let fullName: String
        let owner: NotificationOwner

        struct NotificationOwner: Codable {
            let avatarUrl: String
        }
    }
}
