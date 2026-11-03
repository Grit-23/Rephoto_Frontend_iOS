//
//  PhotoMetadataExtractorProtocol.swift
//  PhotoDomainInterface
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

/// 이미지 원본 데이터에서 업로드용 메타데이터(위치/촬영시간)와 압축본을 추출하는 계약.
/// 구현체(ImageIO/파일 I/O)는 구현 모듈에 있다.
/// @mockable
public protocol PhotoMetadataExtractorProtocol: Sendable {
    func extract(from imageData: Data, identifier: String?) async -> PhotoUploadItem?
}
