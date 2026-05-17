import Foundation

enum RepositoryError: LocalizedError {
    case httpError(Int)
    case decodingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingFailed:
            return "Failed to decode response"
        case .unknown:
            return "Unknown error"
        }
    }
}
