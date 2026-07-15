//
//  NetworkAdapter.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

/// APITargetType을 NetworkClient와 연동하는 어댑터
///
/// APITargetType → URLRequest로 변환 후 NetworkClient에 위임
struct NetworkAdapter {
    private let networkClient: NetworkClient
    private let baseURL: URL

    init(networkClient: NetworkClient, baseURL: URL) {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }

    /// API를 요청하고 NetworkResponse를 반환
    func request<T: APITargetType>(_ target: T) async throws -> NetworkResponse {
        let urlRequest = try buildURLRequest(target)

        #if DEBUG
        logRequest(urlRequest)
        #endif

        do {
            let (data, httpResponse) = try await networkClient.request(urlRequest)

            #if DEBUG
            logResponse(httpResponse, data: data, request: urlRequest)
            #endif

            return NetworkResponse(statusCode: httpResponse.statusCode, data: data)
        } catch {
            #if DEBUG
            print("[Network] ERROR \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
            print("  → \(error.localizedDescription)")
            #endif
            throw error
        }
    }
}

// MARK: - Debug Logging

#if DEBUG
extension NetworkAdapter {
    private func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        print("[Network] → \(method) \(url)")
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print("  Body: \(str)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let status = response.statusCode
        let icon = (200..<300).contains(status) ? "OK" : "ERR"
        print("[Network] ← \(icon) \(status) \(method) \(url)")
        if let str = String(data: data, encoding: .utf8) {
            let preview = str.prefix(500)
            print("  Response: \(preview)\(str.count > 500 ? "..." : "")")
        }
    }
}
#endif

// MARK: - URLRequest Builder

extension NetworkAdapter {

    // 테스트에서 URLRequest 조립 결과를 검증할 수 있도록 internal
    func buildURLRequest<T: APITargetType>(_ target: T) throws -> URLRequest {
        // 1. URL 구성 (주입된 baseURL + path)
        let url = baseURL.appending(path: target.path)

        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue

        // 3. Headers 설정
        target.headers?.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        // 4. Task에 따라 Body 설정
        switch target.task {
        case .plain:
            break

        case .jsonEncodable(let encodable):
            request.httpBody = try JSONEncoder().encode(AnyEncodable(encodable))

        case .multipart(let items):
            let (body, boundary) = buildMultipartBody(items)
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func buildMultipartBody(_ items: [MultipartFormItem]) -> (Data, String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let crlf = "\r\n"

        for item in items {
            body.append("--\(boundary)\(crlf)".data(using: .utf8)!)

            var disposition = "Content-Disposition: form-data; name=\"\(item.name)\""
            if let fileName = item.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            body.append("\(disposition)\(crlf)".data(using: .utf8)!)

            if let mimeType = item.mimeType {
                body.append("Content-Type: \(mimeType)\(crlf)".data(using: .utf8)!)
            }

            body.append(crlf.data(using: .utf8)!)
            body.append(item.data)
            body.append(crlf.data(using: .utf8)!)
        }

        body.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
        return (body, boundary)
    }
}

// MARK: - AnyEncodable

fileprivate struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        let wrappedValue = wrapped
        _encode = { encoder in
            try wrappedValue.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
