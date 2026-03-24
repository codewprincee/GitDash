import SwiftUI

struct IssueDetailView: View {
    let issue: GitHubIssue
    @State private var comments: [IssueComment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var actionMessage: String?

    private var repoFullName: String {
        // Extract from htmlUrl: https://github.com/owner/repo/issues/123
        let parts = issue.htmlUrl.replacingOccurrences(of: "https://github.com/", with: "").split(separator: "/")
        guard parts.count >= 2 else { return "" }
        return "\(parts[0])/\(parts[1])"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(issue.state == "open" ? .green : .purple)
                    Text(issue.title)
                        .font(.title3.bold())
                        .lineLimit(3)
                    Spacer()
                    Text("#\(issue.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    AvatarView(url: issue.user.avatarUrl, size: 18)
                    Text(issue.user.login).font(.caption).foregroundStyle(.secondary)
                    Text(issue.state.capitalized)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(issue.state == "open" ? .green.opacity(0.2) : .purple.opacity(0.2), in: Capsule())
                    if let labels = issue.labels {
                        ForEach(labels) { label in
                            LabelBadge(name: label.name, colorHex: label.color)
                        }
                    }
                    Spacer()
                    Button("Open in GitHub") {
                        if let url = URL(string: issue.htmlUrl) { NSWorkspace.shared.open(url) }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
            .padding()

            Divider()

            // Body + Comments
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Issue body
                    if let body = issue.body, !body.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    AvatarView(url: issue.user.avatarUrl, size: 16)
                                    Text(issue.user.login).font(.caption.bold())
                                    RelativeTimeText(dateString: issue.createdAt)
                                    Spacer()
                                }
                                Divider()
                                Text(body)
                                    .font(.body)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Comments
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        ForEach(comments) { comment in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        AvatarView(url: comment.user.avatarUrl, size: 16)
                                        Text(comment.user.login).font(.caption.bold())
                                        RelativeTimeText(dateString: comment.createdAt)
                                        Spacer()
                                    }
                                    Divider()
                                    Text(comment.body)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    if let msg = actionMessage {
                        Text(msg).font(.caption).foregroundStyle(.green)
                    }
                }
                .padding()
            }

            Divider()

            // Comment box
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                Button("Comment") { Task { await postComment() } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .task { await fetchComments() }
    }

    private func fetchComments() async {
        isLoading = true
        do {
            comments = try await GitHubAPIClient.shared.get(
                "/repos/\(repoFullName)/issues/\(issue.number)/comments",
                queryItems: [URLQueryItem(name: "per_page", value: "50")]
            )
        } catch {}
        isLoading = false
    }

    private func postComment() async {
        guard !newComment.isEmpty else { return }
        do {
            let _: IssueComment = try await GitHubAPIClient.shared.post(
                "/repos/\(repoFullName)/issues/\(issue.number)/comments",
                body: ["body": newComment]
            )
            newComment = ""
            actionMessage = "✓ Comment posted"
            await fetchComments()
        } catch {
            actionMessage = "Error: \(error.localizedDescription)"
        }
    }
}

struct IssueComment: Codable, Identifiable {
    let id: Int
    let user: GitHubUser
    let body: String
    let createdAt: String
    let updatedAt: String
}
