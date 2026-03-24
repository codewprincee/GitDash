import Foundation

struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let owner: GitHubOwner
    let htmlUrl: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
    let isPrivate: Bool
    let archived: Bool
    let defaultBranch: String
    let updatedAt: String?
    let pushedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, fullName, owner, htmlUrl, description, language
        case stargazersCount, forksCount, openIssuesCount
        case isPrivate = "private"
        case archived, defaultBranch, updatedAt, pushedAt
    }
}

struct GitHubOwner: Codable {
    let login: String
    let avatarUrl: String
}
