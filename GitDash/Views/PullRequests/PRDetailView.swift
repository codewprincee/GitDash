import SwiftUI

struct PRDetailView: View {
    let pr: GitHubPullRequest
    @Environment(AuthenticationManager.self) private var auth
    @State private var diff: String?
    @State private var isLoadingDiff = false
    @State private var showMergeConfirm = false
    @State private var showApproveConfirm = false
    @State private var commentText = ""
    @State private var actionMessage: String?
    @State private var actionError: String?
    @State private var reviews: [GitHubReview] = []

    private var repoComponents: (owner: String, repo: String)? {
        let parts = (pr.base.repo?.fullName ?? "").split(separator: "/")
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            tabContent
        }
        .task { await loadDiff() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pr.title)
                        .font(.title3.bold())
                        .lineLimit(3)
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.pull")
                            .foregroundStyle(pr.state == "open" ? .green : .purple)

                        Text("#\(pr.number)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if pr.draft == true {
                            Text("Draft")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.yellow.opacity(0.2), in: Capsule())
                                .foregroundStyle(.yellow)
                        }

                        Text(pr.state.capitalized)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(pr.state == "open" ? .green.opacity(0.2) : .purple.opacity(0.2), in: Capsule())
                            .foregroundStyle(pr.state == "open" ? .green : .purple)

                        AvatarView(url: pr.user.avatarUrl, size: 18)
                        Text(pr.user.login)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        RelativeTimeText(dateString: pr.createdAt)
                    }
                }
            }

            // Branch info
            HStack(spacing: 4) {
                Text(pr.head.ref)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(pr.base.ref)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))

                Spacer()

                if let additions = pr.additions, let deletions = pr.deletions {
                    Text("+\(additions)")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    Text("-\(deletions)")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }

                if let files = pr.changedFiles {
                    Text("\(files) files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Labels
            if let labels = pr.labels, !labels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(labels) { label in
                        LabelBadge(name: label.name, colorHex: label.color)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: { showApproveConfirm = true }) {
                    Label("Approve", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)

                Button(action: { showMergeConfirm = true }) {
                    Label("Merge", systemImage: "arrow.triangle.merge")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(pr.state != "open")

                Button("Open in GitHub") {
                    if let url = URL(string: pr.htmlUrl) { NSWorkspace.shared.open(url) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                if let msg = actionMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if let err = actionError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Comment box
            HStack {
                TextField("Leave a comment...", text: $commentText)
                    .textFieldStyle(.roundedBorder)
                Button("Comment") {
                    Task { await submitComment() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .alert("Approve PR?", isPresented: $showApproveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Approve") { Task { await approvePR() } }
        }
        .alert("Merge PR?", isPresented: $showMergeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Merge") { Task { await mergePR() } }
        } message: {
            Text("This will merge \(pr.head.ref) into \(pr.base.ref)")
        }
    }

    // MARK: - Diff Tab

    private var tabContent: some View {
        Group {
            if isLoadingDiff {
                LoadingStateView(message: "Loading diff...")
            } else if let diff {
                PRDiffView(diff: diff)
            } else {
                // Show PR body as fallback
                ScrollView {
                    if let body = pr.body, !body.isEmpty {
                        Text(body)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        EmptyStateView(title: "No Description", subtitle: "This PR has no description.", systemImage: "doc.text")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadDiff() async {
        guard let r = repoComponents else { return }
        isLoadingDiff = true
        do {
            diff = try await GitHubAPIClient.shared.getRaw("/repos/\(r.owner)/\(r.repo)/pulls/\(pr.number)")
        } catch {
            diff = nil
        }
        isLoadingDiff = false
    }

    private func approvePR() async {
        guard let r = repoComponents else { return }
        do {
            let _: ReviewResponse = try await GitHubAPIClient.shared.post(
                "/repos/\(r.owner)/\(r.repo)/pulls/\(pr.number)/reviews",
                body: ["event": "APPROVE"]
            )
            actionMessage = "✓ Approved"
            actionError = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func mergePR() async {
        guard let r = repoComponents else { return }
        do {
            let _: MergeResponse = try await GitHubAPIClient.shared.put(
                "/repos/\(r.owner)/\(r.repo)/pulls/\(pr.number)/merge"
            )
            actionMessage = "✓ Merged"
            actionError = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func submitComment() async {
        guard let r = repoComponents, !commentText.isEmpty else { return }
        do {
            let _: CommentResponse = try await GitHubAPIClient.shared.post(
                "/repos/\(r.owner)/\(r.repo)/issues/\(pr.number)/comments",
                body: ["body": commentText]
            )
            actionMessage = "✓ Comment posted"
            commentText = ""
        } catch {
            actionError = error.localizedDescription
        }
    }
}

struct GitHubReview: Codable, Identifiable {
    let id: Int
    let user: GitHubUser
    let state: String
    let body: String?
    let submittedAt: String?
}

struct CommentResponse: Codable {
    let id: Int
    let body: String
}
