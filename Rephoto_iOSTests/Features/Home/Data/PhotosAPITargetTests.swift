//
//  PhotosAPITargetTests.swift
//  Rephoto_iOSTests
//
//  Created by Doyeon Kim on 8/2/26.
//

import Foundation
import Testing
@testable import Rephoto_iOS

/// PhotosAPITarget의 엔드포인트 계약 검증.
///
/// 서버 스펙(path/method/바디 구성)이 바뀌면 컴파일은 통과해도 런타임에서만 깨지므로,
/// 순수 함수인 target 선언 자체를 값으로 고정해 스펙 변경의 1차 방어선을 만든다.
@Suite("PhotosAPITarget — 엔드포인트 계약")
struct PhotosAPITargetTests {

    // MARK: - path / method

    @Test("getAllPhotos — GET /photos")
    func getAllPhotos() {
        let target = PhotosAPITarget.getAllPhotos

        #expect(target.path == "/photos")
        #expect(target.method == .get)
        #expect(target.task.isPlain)
    }

    @Test("deletePhoto — photoId가 path에 보간된다", arguments: [1, 42, 9999])
    func deletePhoto(photoId: Int) {
        let target = PhotosAPITarget.deletePhoto(photoId: photoId)

        #expect(target.path == "/photos/\(photoId)")
        #expect(target.method == .delete)
        #expect(target.task.isPlain)
    }

    @Test("s3Upload — POST /photos/s3")
    func s3UploadPathAndMethod() {
        let target = PhotosAPITarget.s3Upload(file: Data("img".utf8))

        #expect(target.path == "/photos/s3")
        #expect(target.method == .post)
    }

    @Test("savePhotosBatch — POST /photos/batch")
    func savePhotosBatchPathAndMethod() {
        let target = PhotosAPITarget.savePhotosBatch(request: PhotoBatchRequestDTO(photos: []))

        #expect(target.path == "/photos/batch")
        #expect(target.method == .post)
    }

    // MARK: - task

    /// 파일 파트 이름·파일명·MIME은 서버가 파싱 기준으로 삼는 값이라 함께 고정한다.
    @Test("s3Upload — file 파트 하나로 multipart를 구성하고 원본 바이트를 보존한다")
    func s3UploadBuildsMultipart() throws {
        // JPEG 헤더 유사 바이트 — UTF-8로 디코딩 불가한 바이너리
        let fileData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        let target = PhotosAPITarget.s3Upload(file: fileData)

        let items = try #require(target.task.multipartItems, "task가 .multipart가 아님")
        #expect(items.count == 1)
        #expect(items[0].name == "file")
        #expect(items[0].fileName == "photo.jpg")
        #expect(items[0].mimeType == "image/jpeg")
        #expect(items[0].data == fileData)
    }

    @Test("savePhotosBatch — 메타데이터 배열을 그대로 JSON 바디에 싣는다")
    func savePhotosBatchCarriesMetadata() throws {
        let metadata = PhotoMetadataDTO(
            latitude: 33.4507,
            longitude: 126.5706,
            imageUrl: "https://cdn.test/jeju.jpg",
            createdAt: "2026-08-02T09:30:00Z",
            fileName: "jeju.jpg"
        )
        let target = PhotosAPITarget.savePhotosBatch(request: PhotoBatchRequestDTO(photos: [metadata]))

        let body = try #require(target.task.jsonBody(as: PhotoBatchRequestDTO.self), "task가 .jsonEncodable이 아님")
        #expect(body.photos.count == 1)
        #expect(body.photos[0].latitude == 33.4507)
        #expect(body.photos[0].longitude == 126.5706)
        #expect(body.photos[0].imageUrl == "https://cdn.test/jeju.jpg")
        #expect(body.photos[0].createdAt == "2026-08-02T09:30:00Z")
        #expect(body.photos[0].fileName == "jeju.jpg")
    }

    // MARK: - headers

    /// s3Upload만 헤더를 nil로 내려 NetworkAdapter가 boundary 포함 Content-Type을 설정하게 위임한다.
    @Test("s3Upload — Content-Type을 타겟에서 지정하지 않는다")
    func s3UploadOmitsContentTypeHeader() {
        #expect(PhotosAPITarget.s3Upload(file: Data()).headers == nil)
    }

    @Test("multipart가 아닌 케이스는 JSON 기본 헤더를 유지한다")
    func nonMultipartCasesUseJSONHeader() {
        let targets: [PhotosAPITarget] = [
            .getAllPhotos,
            .deletePhoto(photoId: 1),
            .savePhotosBatch(request: PhotoBatchRequestDTO(photos: []))
        ]

        for target in targets {
            #expect(target.headers == ["Content-Type": "application/json"])
        }
    }
}
