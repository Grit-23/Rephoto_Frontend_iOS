//
//  TokenRefreshServiceImpl.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation
import RephotoFoundation

public struct TokenRefreshServiceImpl: TokenRefreshService {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    /// 갱신 요청을 보내고 새 토큰 쌍을 돌려준다.
    ///
    /// Approachable Concurrency에서는 nonisolated async가 호출자 액터에서 돌므로,
    /// 인코딩 · 디코딩이 `NetworkClient` actor 위에서 실행되지 않도록 `@concurrent`로 내보낸다.
    @concurrent
    public func refresh(_ refreshToken: String) async throws -> TokenPair {
        let url = baseURL.appending(path: "/auth/refresh")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            RefreshTokenRequestBody(refreshToken: refreshToken)
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: Data())
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
    let refreshToken: String

    /// 서버가 바디 필드명으로 "Authorization"을 기대한다
    enum CodingKeys: String, CodingKey {
        case refreshToken = "Authorization"
    }
}

private struct RefreshResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}
