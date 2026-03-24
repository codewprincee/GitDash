import SwiftUI

struct ActionsListView: View {
    @State private var actionsService = ActionsService()
    @State private var repoService = RepositoryService()
    @State private var selectedRun: GitHubWorkflowRun?
    @State private var polling = PollingManager()

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                if actionsService.isLoading && actionsService.workflowRuns.isEmpty {
                    LoadingStateView(message: "Fetching workflow runs...")
                } else if actionsService.workflowRuns.isEmpty {
                    EmptyStateView(title: "No Workflow Runs", subtitle: "No recent CI/CD runs found.", systemImage: "gearshape.2")
                } else {
                    List(actionsService.workflowRuns, selection: $selectedRun) { run in
                        ActionsRowView(run: run)
                            .tag(run)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 380, max: 500)
        } detail: {
            if let run = selectedRun {
                ActionsDetailView(run: run)
            } else {
                EmptyStateView(title: "Select a Run", subtitle: "Choose a workflow run to view jobs and logs.", systemImage: "gearshape.2")
            }
        }
        .navigationTitle("Actions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .task {
            await refresh()
            polling.startPolling(id: "actions", interval: 30) { await refresh() }
        }
        .onDisappear { polling.stopAll() }
    }

    private func refresh() async {
        await repoService.fetchRepositories()
        await actionsService.fetchRuns(repos: repoService.repositories)
    }
}

struct ActionsRowView: View {
    let run: GitHubWorkflowRun

    var body: some View {
        HStack(spacing: 10) {
            CIStatusBadge(status: run.status, conclusion: run.conclusion)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.name ?? "Workflow")
                    .font(.body.weight(.medium)).lineLimit(1)
                HStack(spacing: 8) {
                    Text(run.repository?.fullName ?? "").font(.caption).foregroundStyle(.secondary)
                    Text(run.headBranch ?? "").font(.caption).foregroundStyle(.tertiary)
                    Text(run.event).font(.caption2).padding(.horizontal, 4).padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }
            Spacer()
            RelativeTimeText(dateString: run.createdAt)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open in GitHub") {
                if let url = URL(string: run.htmlUrl) { NSWorkspace.shared.open(url) }
            }
        }
    }
}
