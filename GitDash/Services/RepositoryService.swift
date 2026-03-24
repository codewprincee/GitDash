import Foundation

@Observable
final class RepositoryService {
    var repositories: [GitHubRepository] = []
    var isLoading = false
    var error: String?

    func fetchRepositories() async {
        isLoading = true
        error = nil
        do {
            let repos: [GitHubRepository] = try await GitHubAPIClient.shared.get(
                "/user/repos",
                queryItems: [
                    URLQueryItem(name: "sort", value: "pushed"),
                    URLQueryItem(name: "per_page", value: "100"),
                    URLQueryItem(name: "type", value: "all")
                ]
            )
            await MainActor.run {
                repositories = repos
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}
