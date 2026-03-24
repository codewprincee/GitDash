import Foundation

@Observable
final class ActionsService {
    var workflowRuns: [GitHubWorkflowRun] = []
    var isLoading = false
    var error: String?

    func fetchRuns(repos: [GitHubRepository]) async {
        isLoading = true
        error = nil

        var allRuns: [GitHubWorkflowRun] = []

        // Fetch runs from top 10 recently pushed repos
        for repo in repos.prefix(10) {
            do {
                let response: GitHubWorkflowRunsResponse = try await GitHubAPIClient.shared.get(
                    "/repos/\(repo.fullName)/actions/runs",
                    queryItems: [URLQueryItem(name: "per_page", value: "5")]
                )
                allRuns.append(contentsOf: response.workflowRuns)
            } catch {
                continue // Skip repos without Actions
            }
        }

        await MainActor.run {
            workflowRuns = allRuns.sorted { $0.createdAt > $1.createdAt }
            isLoading = false
        }
    }

    func rerunFailed(owner: String, repo: String, runID: Int) async throws {
        try await GitHubAPIClient.shared.post(
            "/repos/\(owner)/\(repo)/actions/runs/\(runID)/rerun-failed-jobs",
            body: nil
        ) as EmptyResponse
    }

    func cancelRun(owner: String, repo: String, runID: Int) async throws {
        try await GitHubAPIClient.shared.post(
            "/repos/\(owner)/\(repo)/actions/runs/\(runID)/cancel",
            body: nil
        ) as EmptyResponse
    }
}

struct EmptyResponse: Codable {}
