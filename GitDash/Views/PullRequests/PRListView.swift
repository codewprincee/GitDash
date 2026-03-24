import SwiftUI

struct PRListView: View {
    @Environment(AuthenticationManager.self) private var auth
    @State private var prService = PullRequestService()
    @State private var selectedTab = 0
    @State private var selectedPR: GitHubPullRequest?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Created (\(prService.createdPRs.count))").tag(0)
                    Text("Review (\(prService.reviewRequestedPRs.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                let prs = selectedTab == 0 ? prService.createdPRs : prService.reviewRequestedPRs

                if prService.isLoading && prs.isEmpty {
                    LoadingStateView(message: "Fetching pull requests...")
                } else if prs.isEmpty {
                    EmptyStateView(title: "No Pull Requests", subtitle: "No open PRs found.", systemImage: "arrow.triangle.branch")
                } else {
                    List(prs, selection: $selectedPR) { pr in
                        PRRowView(pr: pr)
                            .tag(pr)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 380, max: 500)
        } detail: {
            if let pr = selectedPR {
                PRDetailView(pr: pr)
            } else {
                EmptyStateView(title: "Select a PR", subtitle: "Choose a pull request to view details and diff.", systemImage: "arrow.triangle.pull")
            }
        }
        .navigationTitle("Pull Requests")
        .task {
            if let user = auth.currentUser {
                await prService.fetchPRs(username: user.login)
            }
        }
        .refreshable {
            if let user = auth.currentUser {
                await prService.fetchPRs(username: user.login)
            }
        }
    }
}

struct PRRowView: View {
    let pr: GitHubPullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(pr.state == "open" ? .green : .purple)
                Text(pr.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Spacer()
                if pr.draft == true {
                    Text("Draft")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }

            HStack(spacing: 8) {
                AvatarView(url: pr.user.avatarUrl, size: 16)
                Text(pr.user.login).font(.caption).foregroundStyle(.secondary)
                Text("#\(pr.number)").font(.caption).foregroundStyle(.tertiary)

                if let labels = pr.labels {
                    ForEach(labels.prefix(3)) { label in
                        LabelBadge(name: label.name, colorHex: label.color)
                    }
                }

                Spacer()

                if let adds = pr.additions, let dels = pr.deletions {
                    Text("+\(adds)").font(.caption2).foregroundStyle(.green)
                    Text("-\(dels)").font(.caption2).foregroundStyle(.red)
                }

                RelativeTimeText(dateString: pr.updatedAt)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open in GitHub") {
                if let url = URL(string: pr.htmlUrl) { NSWorkspace.shared.open(url) }
            }
        }
    }
}
