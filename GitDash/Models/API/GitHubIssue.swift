import Foundation

struct GitHubIssue: Codable, Identifiable, Hashable {
    static func == (lhs: GitHubIssue, rhs: GitHubIssue) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let user: GitHubUser
    let htmlUrl: String
    let createdAt: String
    let updatedAt: String
    let comments: Int
    let labels: [GitHubLabel]?
    let assignees: [GitHubUser]?
    let pullRequest: IssuePR?

    struct IssuePR: Codable {
        let htmlUrl: String?
    }

    var isActualIssue: Bool { pullRequest == nil }
}
