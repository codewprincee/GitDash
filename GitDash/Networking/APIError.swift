import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case rateLimited(retryAfter: Int?)
    case notFound
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Authentication failed. Please log in again."
        case .rateLimited(let retry):
            if let retry { return "Rate limited. Try again in \(retry) seconds." }
            return "Rate limited. Please wait before retrying."
        case .notFound: return "Resource not found."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Failed to parse response: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from server."
        case .unknown(let msg): return msg
        }
    }
}
