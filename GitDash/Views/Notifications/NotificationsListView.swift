import SwiftUI

struct NotificationsListView: View {
    @State private var notifService = NotificationService()
    @State private var filterType: String = "all"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Filter", selection: $filterType) {
                    Text("All").tag("all")
                    Text("Unread").tag("unread")
                    Text("PRs").tag("PullRequest")
                    Text("Issues").tag("Issue")
                }
                .pickerStyle(.segmented)

                Spacer()

                if notifService.unreadCount > 0 {
                    Button("Mark All Read") {
                        Task { try? await notifService.markAllRead() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()

            if notifService.isLoading && notifService.notifications.isEmpty {
                LoadingStateView(message: "Fetching notifications...")
            } else if filteredNotifications.isEmpty {
                EmptyStateView(title: "All Caught Up", subtitle: "No notifications to show.", systemImage: "bell.slash")
            } else {
                List(filteredNotifications) { notif in
                    NotificationRowView(notification: notif)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Notifications (\(notifService.unreadCount) unread)")
        .task { await notifService.fetchNotifications() }
    }

    private var filteredNotifications: [GitHubNotification] {
        switch filterType {
        case "unread": return notifService.notifications.filter(\.unread)
        case "PullRequest": return notifService.notifications.filter { $0.subject.type == "PullRequest" }
        case "Issue": return notifService.notifications.filter { $0.subject.type == "Issue" }
        default: return notifService.notifications
        }
    }
}

struct NotificationRowView: View {
    let notification: GitHubNotification

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: typeIcon)
                .foregroundStyle(notification.unread ? .blue : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.subject.title)
                    .font(.body.weight(notification.unread ? .semibold : .regular))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(notification.repository.fullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notification.reason)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }

            Spacer()

            if notification.unread {
                Circle().fill(.blue).frame(width: 8, height: 8)
            }

            RelativeTimeText(dateString: notification.updatedAt)
        }
        .padding(.vertical, 4)
    }

    private var typeIcon: String {
        switch notification.subject.type {
        case "PullRequest": return "arrow.triangle.pull"
        case "Issue": return "exclamationmark.circle"
        case "Release": return "tag"
        default: return "bell"
        }
    }
}
