//
//  PhotoItem.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/5/26.
//


import Foundation
import SwiftData

///  사진 로컬 저장 모델 (SwiftData)
///
///  홈 화면에서 사용될 이미지 정보를 로컬 DB에 저장하므로써 불필요한 API호출을 방지
@Model
class PhotoItem {
    /// 서버에서 주는 고유 ID/
    @Attribute(.unique) var id: String
    /// 원본 이미지 URL
    var imageUrl: String
    /// DB 용량이 커지는 걸 방지하고 별도 파일로 관리 (성능 최적화)
    @Attribute(.externalStorage) var imageData: Data?
    /// 이미지 생성 시간
    var createdAt: Date

    init(
        id: String,
        imageUrl: String,
        imageData: Data? = nil,
        memo: String? = nil
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.createdAt = Date()
    }
}
