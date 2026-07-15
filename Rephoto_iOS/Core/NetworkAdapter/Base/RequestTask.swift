//
//  RequestTask.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

/// HTTP 요청 바디 구성 방식
///
/// 앱에서 실사용하는 3가지 케이스만 정의한다.
enum RequestTask {
    /// 바디 없음 (조회/삭제 계열)
    case plain
    /// Encodable을 JSON 바디로 인코딩
    case jsonEncodable(any Encodable)
    /// multipart/form-data 업로드
    case multipart([MultipartFormItem])
}
