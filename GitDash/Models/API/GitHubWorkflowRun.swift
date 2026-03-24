import Foundation

struct GitHubWorkflowRun: Codable, Identifiable, Hashable {
    static func == (lhs: GitHubWorkflowRun, rhs: GitHubWorkflowRun) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: Int
    let name: String?
    let headBranch: String?
    let headSha: String
    let status: String  // queued, in_progress, completed
    let conclusion: String?  // success, failure, cancelled, skipped
    let htmlUrl: String
    let createdAt: String
    let updatedAt: String
    let runNumber: Int
    let event: String  // push, pull_request, etc.
    let repository: WorkflowRepo?

    struct WorkflowRepo: Codable, Hashable {
        let fullName: String
    }
}

struct GitHubWorkflowRunsResponse: Codable {
    let totalCount: Int
    let workflowRuns: [GitHubWorkflowRun]
}
