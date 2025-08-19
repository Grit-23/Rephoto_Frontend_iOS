//
//  TagRequestDto.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/17/25.
//

import Foundation

/// 태그 생성 및 수정 요청 DTO
struct TagRequestDto: Codable {
    let tagName: String
}
