import Foundation

@Observable
final class PullRequestService {
    var createdPRs: [GitHubPullRequest] = []
    var reviewRequestedPRs: [GitHubPullRequest] = []
    var isLoading = false
    var error: String?

    func fetchPRs(username: String) async {
        isLoading = true
        error = nil
        do {
            async let created: [GitHubPullRequest] = GitHubAPIClient.shared.get(
                "/search/issues",
                queryItems: [URLQueryItem(name: "q", value: "type:pr author:\(username) is:open")]
            )
            // Note: search API returns items inside { items: [...] }
            // For now, use the simpler notifications approach

            let createdResult: SearchResponse<GitHubPullRequest> = try await GitHubAPIClient.shared.get(
                "/search/issues",
                queryItems: [URLQueryItem(name: "q", value: "type:pr author:\(username) is:open"),
                             URLQueryItem(name: "per_page", value: "50")]
            )

            let reviewResult: SearchResponse<GitHubPullRequest> = try await GitHubAPIClient.shared.get(
                "/search/issues",
                queryItems: [URLQueryItem(name: "q", value: "type:pr review-requested:\(username) is:open"),
                             URLQueryItem(name: "per_page", value: "50")]
            )

            await MainActor.run {
                createdPRs = createdResult.items
                reviewRequestedPRs = reviewResult.items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    func mergePR(owner: String, repo: String, number: Int) async throws {
        let _: MergeResponse = try await GitHubAPIClient.shared.put(
            "/repos/\(owner)/\(repo)/pulls/\(number)/merge"
        )
    }

    func approvePR(owner: String, repo: String, number: Int) async throws {
        let _: ReviewResponse = try await GitHubAPIClient.shared.post(
            "/repos/\(owner)/\(repo)/pulls/\(number)/reviews",
            body: ["event": "APPROVE"]
        )
    }

    func getDiff(owner: String, repo: String, number: Int) async throws -> String {
        try await GitHubAPIClient.shared.getRaw("/repos/\(owner)/\(repo)/pulls/\(number)")
    }
}

struct SearchResponse<T: Codable>: Codable {
    let totalCount: Int
    let items: [T]
}

struct MergeResponse: Codable {
    let sha: String?
    let merged: Bool?
    let message: String?
}

struct ReviewResponse: Codable {
    let id: Int
    let state: String
}
