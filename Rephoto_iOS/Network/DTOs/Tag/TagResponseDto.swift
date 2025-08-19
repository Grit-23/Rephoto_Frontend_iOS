//
//  TagResponseDto.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/17/25.
//

import Foundation

/// 태그 응답 DTO
struct TagResponseDto: Codable {
    let photoTagId: Int       // 사진-태그 매핑 ID
    let tagId: Int            // 태그 ID
    let tagName: String       // 태그명
    let photoId: Int          // 사진 ID
}
