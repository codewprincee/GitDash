import SwiftUI

struct NotificationsListView: View {
    @State private var notifService = NotificationService()
    @State private var filterType = "all"
    @State private var polling = PollingManager()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Filter", selection: $filterType) {
                    Text("All").tag("all")
                    Text("Unread").tag("unread")
                    Text("PRs").tag("PullRequest")
                    Text("Issues").tag("Issue")
                    Text("Releases").tag("Release")
                }
                .pickerStyle(.segmented)

                Spacer()

                if notifService.unreadCount > 0 {
                    Button("Mark All Read") {
                        Task { try? await notifService.markAllRead() }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }

                Button(action: { Task { await notifService.fetchNotifications() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain).help("Refresh")
            }
            .padding()

            if notifService.isLoading && notifService.notifications.isEmpty {
                LoadingStateView(message: "Fetching notifications...")
            } else if filtered.isEmpty {
                EmptyStateView(title: "All Caught Up", subtitle: "No notifications to show.", systemImage: "bell.slash")
            } else {
                List(filtered) { notif in
                    NotificationRowView(notification: notif, onMarkRead: {
                        Task { try? await notifService.markAsRead(threadID: notif.id) }
                    })
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Notifications (\(notifService.unreadCount) unread)")
        .task {
            await notifService.fetchNotifications()
            polling.startPolling(id: "notifications", interval: 60) {
                await notifService.fetchNotifications()
            }
        }
        .onDisappear { polling.stopAll() }
    }

    private var filtered: [GitHubNotification] {
        switch filterType {
        case "unread": return notifService.notifications.filter(\.unread)
        case "PullRequest": return notifService.notifications.filter { $0.subject.type == "PullRequest" }
        case "Issue": return notifService.notifications.filter { $0.subject.type == "Issue" }
        case "Release": return notifService.notifications.filter { $0.subject.type == "Release" }
        default: return notifService.notifications
        }
    }
}

struct NotificationRowView: View {
    let notification: GitHubNotification
    var onMarkRead: () -> Void

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
                        .font(.caption).foregroundStyle(.secondary)
                    Text(notification.reason.replacingOccurrences(of: "_", with: " "))
                        .font(.caption2)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }

            Spacer()

            if notification.unread {
                Button(action: onMarkRead) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Mark as read")
            }

            RelativeTimeText(dateString: notification.updatedAt)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open in GitHub") {
                let url = "https://github.com/\(notification.repository.fullName)"
                if let u = URL(string: url) { NSWorkspace.shared.open(u) }
            }
            if notification.unread {
                Button("Mark as Read", action: onMarkRead)
            }
        }
    }

    private var typeIcon: String {
        switch notification.subject.type {
        case "PullRequest": return "arrow.triangle.pull"
        case "Issue": return "exclamationmark.circle"
        case "Release": return "tag"
        case "Discussion": return "bubble.left.and.bubble.right"
        default: return "bell"
        }
    }
}
