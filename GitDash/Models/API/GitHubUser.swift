import Foundation

struct GitHubUser: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let name: String?
    let bio: String?
    let publicRepos: Int?
    let followers: Int?
    let following: Int?
    let htmlUrl: String?
}
