import SwiftUI

struct IssueCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var auth
    @State private var title = ""
    @State private var issueBody = ""
    @State private var selectedRepo = ""
    @State private var repos: [GitHubRepository] = []
    @State private var labels: [GitHubLabel] = []
    @State private var selectedLabels: Set<String> = []
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Issue")
                    .font(.title3.bold())
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Repo picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repository").font(.caption.bold()).foregroundStyle(.secondary)
                        Picker("Repository", selection: $selectedRepo) {
                            Text("Select a repository...").tag("")
                            ForEach(repos) { repo in
                                Text(repo.fullName).tag(repo.fullName)
                            }
                        }
                        .onChange(of: selectedRepo) { _, newValue in
                            if !newValue.isEmpty { Task { await fetchLabels(for: newValue) } }
                        }
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption.bold()).foregroundStyle(.secondary)
                        TextField("Issue title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Body
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description (Markdown)").font(.caption.bold()).foregroundStyle(.secondary)
                        TextEditor(text: $issueBody)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 150)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
                    }

                    // Labels
                    if !labels.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Labels").font(.caption.bold()).foregroundStyle(.secondary)
                            FlowLayout(spacing: 6) {
                                ForEach(labels) { label in
                                    Button(action: { toggleLabel(label.name) }) {
                                        HStack(spacing: 4) {
                                            Circle().fill(Color(hex: label.color)).frame(width: 8, height: 8)
                                            Text(label.name).font(.caption)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            selectedLabels.contains(label.name)
                                                ? Color(hex: label.color).opacity(0.2)
                                                : Color.clear,
                                            in: Capsule()
                                        )
                                        .overlay(Capsule().strokeBorder(Color(hex: label.color).opacity(0.5)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if let error {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
                .padding()
            }

            Divider()

            // Submit
            HStack {
                Spacer()
                Button(action: { Task { await submitIssue() } }) {
                    if isSubmitting {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Create Issue", systemImage: "plus.circle")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(title.isEmpty || selectedRepo.isEmpty || isSubmitting)
            }
            .padding()
        }
        .frame(width: 560, height: 600)
        .task { await fetchRepos() }
    }

    private func toggleLabel(_ name: String) {
        if selectedLabels.contains(name) { selectedLabels.remove(name) }
        else { selectedLabels.insert(name) }
    }

    private func fetchRepos() async {
        do {
            repos = try await GitHubAPIClient.shared.get(
                "/user/repos",
                queryItems: [URLQueryItem(name: "sort", value: "pushed"),
                             URLQueryItem(name: "per_page", value: "100")]
            )
        } catch {}
    }

    private func fetchLabels(for repoFullName: String) async {
        do {
            labels = try await GitHubAPIClient.shared.get("/repos/\(repoFullName)/labels")
            selectedLabels = []
        } catch { labels = [] }
    }

    private func submitIssue() async {
        isSubmitting = true
        error = nil
        var requestBody: [String: Any] = ["title": title, "body": issueBody]
        if !selectedLabels.isEmpty { requestBody["labels"] = Array(selectedLabels) }

        do {
            let _: GitHubIssue = try await GitHubAPIClient.shared.post(
                "/repos/\(selectedRepo)/issues", body: requestBody
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}

// Simple flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
