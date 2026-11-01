//
//  DefaultAuthenticationPolicy.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 5/31/26.
//

import Foundation

public struct DefaultAuthenticationPolicy: AuthenticationPolicy {

    public init() {}

    public func requireAuthentication(_ request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return true }

        let publicPaths = ["/login", "/join", "/auth/refresh"]
        return !publicPaths.contains(where: { path.hasSuffix($0) })
    }

    public func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}
