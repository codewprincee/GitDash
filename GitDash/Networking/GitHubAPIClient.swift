import Foundation

actor GitHubAPIClient {
    static let shared = GitHubAPIClient()

    private var token: String?
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var rateLimitRemaining: Int = 5000

    func setToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    // MARK: - REST

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", queryItems: queryItems)
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = try buildRequest(path: path, method: "POST")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await execute(request)
    }

    func put<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = try buildRequest(path: path, method: "PUT")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await execute(request)
    }

    func patch<T: Decodable>(_ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = try buildRequest(path: path, method: "PATCH")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await execute(request)
    }

    func delete(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw mapError(statusCode: http.statusCode, data: nil)
        }
    }

    // Raw string response (for diffs)
    func getRaw(_ path: String, accept: String = "application/vnd.github.diff") async throws -> String {
        var request = try buildRequest(path: path, method: "GET")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - GraphQL

    func graphql<T: Decodable>(query: String, variables: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: AppConstants.githubGraphQLEndpoint) else {
            throw APIError.unknown("Invalid GraphQL URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var body: [String: Any] = ["query": query]
        if let variables { body["variables"] = variables }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await execute(request)
    }

    // MARK: - Private

    private func buildRequest(path: String, method: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(string: AppConstants.githubAPIBase + path) else {
            throw APIError.unknown("Invalid URL: \(path)")
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw APIError.unknown("Invalid URL") }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        // Track rate limit
        if let remaining = http.value(forHTTPHeaderField: "X-RateLimit-Remaining") {
            rateLimitRemaining = Int(remaining) ?? rateLimitRemaining
        }

        guard (200...299).contains(http.statusCode) else {
            throw mapError(statusCode: http.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func mapError(statusCode: Int, data: Data?) -> APIError {
        switch statusCode {
        case 401: return .unauthorized
        case 403: return .rateLimited(retryAfter: nil)
        case 404: return .notFound
        case 500...599: return .serverError(statusCode: statusCode)
        default: return .unknown("HTTP \(statusCode)")
        }
    }
}
