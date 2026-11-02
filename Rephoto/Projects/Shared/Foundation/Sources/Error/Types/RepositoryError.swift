//
//  RepositoryError.swift
//  RephotoFoundation
//
//  Created by Doyeon Kim on 8/28/26.
//

import Foundation

/// Data 계층에서 발생하는 에러.
///
/// 응답을 받긴 했지만 도메인 모델로 옮길 수 없는 경우를 표현한다.
/// 전송 자체의 실패는 ``NetworkError``가 담당한다.
public enum RepositoryError: Error, LocalizedError, Equatable, Sendable {

    /// 응답을 도메인 모델로 옮기지 못함.
    ///
    /// 디코딩 실패와 의미상 무효(필수 필드 누락, URL 파싱 실패 등)를 구분하지 않는다 —
    /// 사용자에게는 어느 쪽이든 같은 문구를 보여주고, 원인은 `detail`로 로그에만 남긴다.
    case invalidData(detail: String)

    public var errorDescription: String? {
        switch self {
        case .invalidData(let detail):
            return "응답 데이터가 유효하지 않습니다: \(detail)"
        }
    }
}
