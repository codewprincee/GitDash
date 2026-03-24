import SwiftUI

struct IssueListView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var issues: [GitHubIssue] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && issues.isEmpty {
                LoadingStateView(message: "Fetching issues...")
            } else if issues.isEmpty {
                EmptyStateView(title: "No Issues", subtitle: "No open issues assigned to you.", systemImage: "exclamationmark.circle")
            } else {
                List(issues.filter(\.isActualIssue)) { issue in
                    IssueRowView(issue: issue)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Issues")
        .task { await fetchIssues() }
    }

    private func fetchIssues() async {
        guard let user = auth.currentUser else { return }
        isLoading = true
        do {
            let response: SearchResponse<GitHubIssue> = try await GitHubAPIClient.shared.get(
                "/search/issues",
                queryItems: [
                    URLQueryItem(name: "q", value: "type:issue assignee:\(user.login) is:open"),
                    URLQueryItem(name: "per_page", value: "50")
                ]
            )
            issues = response.items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct IssueRowView: View {
    let issue: GitHubIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(issue.state == "open" ? .green : .purple)
                Text(issue.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text("#\(issue.number)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 8) {
                AvatarView(url: issue.user.avatarUrl, size: 16)
                Text(issue.user.login).font(.caption).foregroundStyle(.secondary)

                if let labels = issue.labels {
                    ForEach(labels.prefix(3)) { label in
                        LabelBadge(name: label.name, colorHex: label.color)
                    }
                }

                Spacer()

                if issue.comments > 0 {
                    Label("\(issue.comments)", systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                RelativeTimeText(dateString: issue.updatedAt)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open in GitHub") {
                if let url = URL(string: issue.htmlUrl) { NSWorkspace.shared.open(url) }
            }
        }
    }
}
