import SwiftUI

struct ActionsListView: View {
    @State private var actionsService = ActionsService()
    @State private var repoService = RepositoryService()

    var body: some View {
        Group {
            if actionsService.isLoading && actionsService.workflowRuns.isEmpty {
                LoadingStateView(message: "Fetching workflow runs...")
            } else if actionsService.workflowRuns.isEmpty {
                EmptyStateView(title: "No Workflow Runs", subtitle: "No recent CI/CD runs found.", systemImage: "gearshape.2")
            } else {
                List(actionsService.workflowRuns) { run in
                    ActionsRowView(run: run)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Actions")
        .task {
            await repoService.fetchRepositories()
            await actionsService.fetchRuns(repos: repoService.repositories)
        }
    }
}

struct ActionsRowView: View {
    let run: GitHubWorkflowRun

    var body: some View {
        HStack(spacing: 10) {
            CIStatusBadge(status: run.status, conclusion: run.conclusion)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.name ?? "Workflow")
                    .font(.body.weight(.medium))
                    .lineLimit(1)

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
            if run.conclusion == "failure" {
                Button("Re-run Failed Jobs") {
                    // TODO: implement re-run
                }
            }
        }
    }
}
