//
//  TokenRefreshServiceImpl.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

struct TokenRefreshServiceImpl: TokenRefreshService {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        let url = baseURL.appending(path: "/auth/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RefreshTokenRequestBody(Authorization: refreshToken)
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TokenRefreshError.serverError(statusCode: httpResponse.statusCode)
        }

        let dto = try decoder.decode(RefreshResponseDTO.self, from: data)

        return TokenPair(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken
        )
    }
}

// MARK: - Request / Response DTOs

private struct RefreshTokenRequestBody: Encodable {
    let Authorization: String
}

private struct RefreshResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Errors

public enum TokenRefreshError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "잘못된 서버 응답"
        case .serverError(let statusCode):
            return "서버 에러 (status: \(statusCode))"
        }
    }
}
