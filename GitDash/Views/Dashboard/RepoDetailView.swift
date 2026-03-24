import SwiftUI

struct RepoDetailView: View {
    let repo: GitHubRepository
    @State private var selectedTab = 0
    @State private var prs: [GitHubPullRequest] = []
    @State private var issues: [GitHubIssue] = []
    @State private var runs: [GitHubWorkflowRun] = []
    @State private var isLoading = true

    private var owner: String { repo.owner.login }
    private var name: String { repo.name }

    var body: some View {
        VStack(spacing: 0) {
            // Repo header
            repoHeader

            Divider()

            // Tabs
            Picker("", selection: $selectedTab) {
                Text("Pull Requests (\(prs.count))").tag(0)
                Text("Issues (\(issues.count))").tag(1)
                Text("Actions (\(runs.count))").tag(2)
                Text("About").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab content
            switch selectedTab {
            case 0: prTab
            case 1: issueTab
            case 2: actionsTab
            case 3: aboutTab
            default: EmptyView()
            }
        }
        .task { await loadData() }
    }

    // MARK: - Header

    private var repoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AvatarView(url: repo.owner.avatarUrl, size: 28)
                Text(repo.fullName).font(.title2.bold())
                if repo.isPrivate {
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.orange)
                }
                Spacer()
                Button("Open in GitHub") {
                    if let url = URL(string: repo.htmlUrl) { NSWorkspace.shared.open(url) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let desc = repo.description {
                Text(desc).font(.body).foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if let lang = repo.language {
                    HStack(spacing: 4) {
                        Circle().fill(.blue).frame(width: 8, height: 8)
                        Text(lang).font(.caption)
                    }
                }
                Label("\(repo.stargazersCount)", systemImage: "star").font(.caption).foregroundStyle(.secondary)
                Label("\(repo.forksCount)", systemImage: "tuningfork").font(.caption).foregroundStyle(.secondary)
                Label("\(repo.openIssuesCount)", systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(.secondary)
                Text("Default: \(repo.defaultBranch)").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    // MARK: - PR Tab

    private var prTab: some View {
        Group {
            if isLoading {
                LoadingStateView()
            } else if prs.isEmpty {
                EmptyStateView(title: "No Open PRs", subtitle: "This repo has no open pull requests.", systemImage: "arrow.triangle.branch")
            } else {
                List(prs) { pr in
                    NavigationLink(value: pr) {
                        PRRowView(pr: pr)
                    }
                }
                .listStyle(.inset)
                .navigationDestination(for: GitHubPullRequest.self) { pr in
                    PRDetailView(pr: pr)
                }
            }
        }
    }

    // MARK: - Issue Tab

    private var issueTab: some View {
        Group {
            if isLoading {
                LoadingStateView()
            } else if issues.isEmpty {
                EmptyStateView(title: "No Open Issues", subtitle: "This repo has no open issues.", systemImage: "exclamationmark.circle")
            } else {
                List(issues.filter(\.isActualIssue)) { issue in
                    IssueRowView(issue: issue)
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        Group {
            if isLoading {
                LoadingStateView()
            } else if runs.isEmpty {
                EmptyStateView(title: "No Workflow Runs", subtitle: "No CI/CD runs found for this repo.", systemImage: "gearshape.2")
            } else {
                List(runs) { run in
                    ActionsRowView(run: run)
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Repository Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow("Owner", value: repo.owner.login)
                        infoRow("Default Branch", value: repo.defaultBranch)
                        infoRow("Visibility", value: repo.isPrivate ? "Private" : "Public")
                        infoRow("Archived", value: repo.archived ? "Yes" : "No")
                        if let lang = repo.language { infoRow("Language", value: lang) }
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Quick Actions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Clone Repository") { cloneRepo() }
                        Button("Copy Clone URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("https://github.com/\(repo.fullName).git", forType: .string)
                        }
                        Button("Open in GitHub") {
                            if let url = URL(string: repo.htmlUrl) { NSWorkspace.shared.open(url) }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
            Text(value).font(.caption.bold())
            Spacer()
        }
    }

    private func cloneRepo() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Clone Here"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["clone", "https://github.com/\(repo.fullName).git"]
            process.currentDirectoryURL = url
            try? process.run()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        async let fetchPRs: [GitHubPullRequest] = GitHubAPIClient.shared.get(
            "/repos/\(repo.fullName)/pulls",
            queryItems: [URLQueryItem(name: "state", value: "open"), URLQueryItem(name: "per_page", value: "30")]
        )
        async let fetchIssues: [GitHubIssue] = GitHubAPIClient.shared.get(
            "/repos/\(repo.fullName)/issues",
            queryItems: [URLQueryItem(name: "state", value: "open"), URLQueryItem(name: "per_page", value: "30")]
        )
        async let fetchRuns: GitHubWorkflowRunsResponse = GitHubAPIClient.shared.get(
            "/repos/\(repo.fullName)/actions/runs",
            queryItems: [URLQueryItem(name: "per_page", value: "15")]
        )

        do {
            let (prResult, issueResult, runResult) = try await (fetchPRs, fetchIssues, fetchRuns)
            prs = prResult
            issues = issueResult
            runs = runResult.workflowRuns
        } catch {
            // Silently fail — some repos might not have Actions enabled
        }
        isLoading = false
    }
}
