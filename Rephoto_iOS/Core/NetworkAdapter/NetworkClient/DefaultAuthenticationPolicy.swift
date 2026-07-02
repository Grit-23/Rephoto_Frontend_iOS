//
//  DefaultAuthenticationPolicy.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

struct DefaultAuthenticationPolicy: AuthenticationPolicy, Sendable {

    nonisolated init() {}

    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return true }

        let publicPaths = ["/login", "/join", "/auth/refresh"]
        return !publicPaths.contains(where: { path.hasSuffix($0) })
    }

    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}
