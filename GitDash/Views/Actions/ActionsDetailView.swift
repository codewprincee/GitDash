import SwiftUI

struct ActionsDetailView: View {
    let run: GitHubWorkflowRun
    @State private var jobs: [WorkflowJob] = []
    @State private var selectedJob: WorkflowJob?
    @State private var jobLog: String?
    @State private var isLoading = true
    @State private var actionMessage: String?

    private var repoFullName: String {
        run.repository?.fullName ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CIStatusBadge(status: run.status, conclusion: run.conclusion)
                    Text(run.name ?? "Workflow Run #\(run.runNumber)")
                        .font(.title3.bold())
                    Spacer()
                    RelativeTimeText(dateString: run.createdAt)
                }

                HStack(spacing: 12) {
                    if !repoFullName.isEmpty {
                        Text(repoFullName).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(run.headBranch ?? "").font(.caption.monospaced())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    Text(run.event).font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                    Text(String(run.headSha.prefix(7))).font(.caption.monospaced()).foregroundStyle(.tertiary)

                    Spacer()

                    // Actions
                    if run.conclusion == "failure" {
                        Button("Re-run Failed") { Task { await rerunFailed() } }
                            .buttonStyle(.borderedProminent).tint(.orange).controlSize(.small)
                    }
                    if run.status == "in_progress" || run.status == "queued" {
                        Button("Cancel") { Task { await cancelRun() } }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                    Button("Open in GitHub") {
                        if let url = URL(string: run.htmlUrl) { NSWorkspace.shared.open(url) }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }

                if let msg = actionMessage {
                    Text(msg).font(.caption).foregroundStyle(.green)
                }
            }
            .padding()

            Divider()

            // Jobs + Logs
            if isLoading {
                LoadingStateView(message: "Loading jobs...")
            } else if jobs.isEmpty {
                EmptyStateView(title: "No Jobs", subtitle: "No job data available.", systemImage: "gearshape")
            } else {
                HSplitView {
                    // Jobs list
                    List(jobs, selection: $selectedJob) { job in
                        HStack(spacing: 8) {
                            CIStatusBadge(status: job.status, conclusion: job.conclusion)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(job.name).font(.body.weight(.medium))
                                if let dur = job.durationText {
                                    Text(dur).font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                        }
                        .tag(job)
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                    .frame(minWidth: 200, idealWidth: 250)

                    // Log viewer
                    if let log = jobLog {
                        ScrollView([.horizontal, .vertical]) {
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                    } else if selectedJob != nil {
                        LoadingStateView(message: "Loading logs...")
                    } else {
                        EmptyStateView(title: "Select a Job", subtitle: "Choose a job to view its logs.", systemImage: "doc.text")
                    }
                }
            }
        }
        .task { await fetchJobs() }
        .onChange(of: selectedJob) { _, newJob in
            if let job = newJob { Task { await fetchLog(jobID: job.id) } }
        }
    }

    private func fetchJobs() async {
        guard !repoFullName.isEmpty else { return }
        isLoading = true
        do {
            let response: JobsResponse = try await GitHubAPIClient.shared.get(
                "/repos/\(repoFullName)/actions/runs/\(run.id)/jobs"
            )
            jobs = response.jobs
            if let first = jobs.first { selectedJob = first }
        } catch {}
        isLoading = false
    }

    private func fetchLog(jobID: Int) async {
        guard !repoFullName.isEmpty else { return }
        jobLog = nil
        do {
            jobLog = try await GitHubAPIClient.shared.getRaw(
                "/repos/\(repoFullName)/actions/jobs/\(jobID)/logs",
                accept: "application/vnd.github+json"
            )
        } catch {
            jobLog = "Failed to load logs: \(error.localizedDescription)"
        }
    }

    private func rerunFailed() async {
        guard !repoFullName.isEmpty else { return }
        do {
            let _: EmptyResponse = try await GitHubAPIClient.shared.post(
                "/repos/\(repoFullName)/actions/runs/\(run.id)/rerun-failed-jobs", body: nil
            )
            actionMessage = "✓ Re-run triggered"
        } catch { actionMessage = "Error: \(error.localizedDescription)" }
    }

    private func cancelRun() async {
        guard !repoFullName.isEmpty else { return }
        do {
            let _: EmptyResponse = try await GitHubAPIClient.shared.post(
                "/repos/\(repoFullName)/actions/runs/\(run.id)/cancel", body: nil
            )
            actionMessage = "✓ Run cancelled"
        } catch { actionMessage = "Error: \(error.localizedDescription)" }
    }
}

// MARK: - Models

struct WorkflowJob: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
    let startedAt: String?
    let completedAt: String?

    static func == (lhs: WorkflowJob, rhs: WorkflowJob) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var durationText: String? {
        guard let start = startedAt, let end = completedAt else { return nil }
        let fmt = ISO8601DateFormatter()
        guard let s = fmt.date(from: start), let e = fmt.date(from: end) else { return nil }
        let secs = Int(e.timeIntervalSince(s))
        if secs < 60 { return "\(secs)s" }
        return "\(secs / 60)m \(secs % 60)s"
    }
}

struct JobsResponse: Codable {
    let totalCount: Int
    let jobs: [WorkflowJob]
}
