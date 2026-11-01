//
//  Config.swift
//  RephotoFoundation
//
//  Created by 김도연 on 8/4/25.
//

import Foundation

public enum Config {
    // `[String: Any]`는 Sendable이 아니라 저장 프로퍼티로 두면 Swift 6가 전역 가변 상태로 본다.
    // 계산 프로퍼티로 두고, 실제로 캐싱되는 값은 Sendable한 `baseURL`(String)뿐이다.
    private static var infoDictionary: [String: Any] {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist cannot be found")
        }
        return dict
    }

    public static let baseURL: String = {
        guard let baseURL = Config.infoDictionary["BASE_URL"] as? String else {
            fatalError("BaseURL not found")
        }
        return baseURL
    }()
}
