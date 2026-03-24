import SwiftUI

struct IssueListView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var issues: [GitHubIssue] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showCreateIssue = false
    @State private var selectedIssue: GitHubIssue?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    Picker("", selection: $selectedTab) {
                        Text("Assigned").tag(0)
                        Text("Created").tag(1)
                        Text("Mentioned").tag(2)
                    }
                    .pickerStyle(.segmented)

                    Button(action: { showCreateIssue = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()

                if isLoading && issues.isEmpty {
                    LoadingStateView(message: "Fetching issues...")
                } else if displayedIssues.isEmpty {
                    EmptyStateView(title: "No Issues", subtitle: "No open issues found.", systemImage: "exclamationmark.circle")
                } else {
                    List(displayedIssues, selection: $selectedIssue) { issue in
                        IssueRowView(issue: issue)
                            .tag(issue)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 380, max: 500)
        } detail: {
            if let issue = selectedIssue {
                IssueDetailView(issue: issue)
            } else {
                EmptyStateView(title: "Select an Issue", subtitle: "Choose an issue to view details and comments.", systemImage: "exclamationmark.circle")
            }
        }
        .navigationTitle("Issues")
        .task { await fetchIssues() }
        .onChange(of: selectedTab) { _, _ in Task { await fetchIssues() } }
        .sheet(isPresented: $showCreateIssue) {
            IssueCreateView()
        }
    }

    private var displayedIssues: [GitHubIssue] {
        issues.filter(\.isActualIssue)
    }

    private func fetchIssues() async {
        guard let user = auth.currentUser else { return }
        isLoading = true
        let qualifier: String
        switch selectedTab {
        case 0: qualifier = "assignee:\(user.login)"
        case 1: qualifier = "author:\(user.login)"
        case 2: qualifier = "mentions:\(user.login)"
        default: qualifier = "assignee:\(user.login)"
        }
        do {
            let response: SearchResponse<GitHubIssue> = try await GitHubAPIClient.shared.get(
                "/search/issues",
                queryItems: [
                    URLQueryItem(name: "q", value: "type:issue \(qualifier) is:open"),
                    URLQueryItem(name: "per_page", value: "50")
                ]
            )
            issues = response.items
        } catch {}
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
                Text(issue.title).font(.body.weight(.medium)).lineLimit(1)
                Spacer()
                Text("#\(issue.number)").font(.caption).foregroundStyle(.tertiary)
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
                    Label("\(issue.comments)", systemImage: "bubble.left").font(.caption2).foregroundStyle(.secondary)
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
