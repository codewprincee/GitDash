import Foundation

struct GitHubPullRequest: Codable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let user: GitHubUser
    let htmlUrl: String
    let createdAt: String
    let updatedAt: String
    let mergedAt: String?
    let draft: Bool?
    let head: GitHubBranch
    let base: GitHubBranch
    let additions: Int?
    let deletions: Int?
    let changedFiles: Int?
    let labels: [GitHubLabel]?
    let requestedReviewers: [GitHubUser]?
}

struct GitHubBranch: Codable {
    let ref: String
    let sha: String
    let repo: GitHubBranchRepo?
}

struct GitHubBranchRepo: Codable {
    let fullName: String
}

struct GitHubLabel: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String
    let description: String?
}
