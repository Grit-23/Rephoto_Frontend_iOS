//
//  MockHomeUseCaseProvider.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/19/26.
//

#if DEBUG
import Foundation

final class MockHomeUseCaseProvider: HomeUseCaseProviderProtocol {
    func makeGetPhotosUseCase() -> GetPhotosUseCaseProtocol { MockGetPhotosUseCase() }
    func makeUploadPhotosUseCase() -> UploadPhotosUseCaseProtocol { MockUploadPhotosUseCase() }
    func makeExtractPhotoMetadataUseCase() -> ExtractPhotoMetadataUseCaseProtocol { MockExtractPhotoMetadataUseCase() }
    func makeDeletePhotoUseCase() -> DeletePhotoUseCaseProtocol { MockDeletePhotoUseCase() }
    func makeGetTagsUseCase() -> GetTagsUseCaseProtocol { MockGetTagsUseCase() }
    func makeAddTagUseCase() -> AddTagUseCaseProtocol { MockAddTagUseCase() }
    func makeUpdateTagUseCase() -> UpdateTagUseCaseProtocol { MockUpdateTagUseCase() }
    func makeDeleteTagUseCase() -> DeleteTagUseCaseProtocol { MockDeleteTagUseCase() }
    func makeGetDescriptionUseCase() -> GetDescriptionUseCaseProtocol { MockGetDescriptionUseCase() }
}

// MARK: - MockPhotoFixtures

/// Resources/MockImages의 실제 사진과 1:1로 매칭되는 데모 픽스처.
/// 태그·AI 설명·좌표·촬영일이 사진 내용/EXIF 기준으로 작성되어 있음.
/// photoId는 배열 순서(최신순) 기반 index + 1 — GetPhotos/GetTags/GetDescription이 모두 이 데이터를 공유.
/// Search 데모(MockSearchUseCaseProvider)도 같은 사진을 앨범/검색 결과로 재사용한다
enum MockPhotoFixtures {
    struct Entry {
        let fileName: String
        let tags: [String]
        let description: String
        let latitude: Double
        let longitude: Double
        let createdAt: String  // ISO8601
        var isSensitive: Bool = false
    }

    static let entries: [Entry] = [
        Entry(
            fileName: "IMG_2015.JPG",
            tags: ["해방촌", "노을"],
            description: "해 질 녘 옥상에서 내려다본 해방촌 주택가 풍경입니다. 분홍빛으로 물든 하늘 아래 낮은 지붕들이 겹겹이 이어져 있어요.",
            latitude: 37.544113, longitude: 126.987962,
            createdAt: "2026-07-13T10:45:07Z"
        ),
        Entry(
            fileName: "IMG_7350.jpeg",
            tags: ["산책", "시골길"],
            description: "수풀이 우거진 굴다리 아래로 좁은 길이 이어집니다. '집으로 가시는 길' 표지판이 정겨운 분위기를 더해요.",
            latitude: 38.019283, longitude: 127.364792,
            createdAt: "2026-07-08T02:07:01Z"
        ),
        Entry(
            fileName: "IMG_0871.jpeg",
            tags: ["연등", "축제"],
            description: "알록달록한 연등이 줄지어 걸린 거리 풍경입니다. 흐린 하늘 아래에서도 연등 색이 선명하게 살아 있어요.",
            latitude: 37.558037, longitude: 126.999863,
            createdAt: "2026-06-25T04:44:43Z"
        ),
        Entry(
            fileName: "IMG_0813.jpeg",
            tags: ["카페", "커피"],
            description: "카페에서 받은 에티오피아 시다마 원두 카드입니다. 창가로 들어온 햇살이 카드 위에 부드럽게 드리워져 있어요.",
            latitude: 37.539475, longitude: 127.007828,
            createdAt: "2026-06-18T07:30:37Z"
        ),
        Entry(
            fileName: "IMG_0689.jpeg",
            tags: ["남산타워", "퇴근길"],
            description: "충무로 거리에서 올려다본 남산서울타워입니다. 맑은 저녁 하늘 아래 타워가 또렷하게 보여요.",
            latitude: 37.562180, longitude: 126.997672,
            createdAt: "2026-06-11T09:24:21Z"
        ),
        Entry(
            fileName: "IMG_0673.jpeg",
            tags: ["도넛", "간식"],
            description: "글레이즈드 도넛 두 개와 커피 한 병. 달콤한 휴식 시간의 기록입니다.",
            latitude: 37.558342, longitude: 126.998328,
            createdAt: "2026-06-10T04:13:37Z"
        ),
        Entry(
            fileName: "IMG_0446.jpeg",
            tags: ["학교", "일상"],
            description: "강의실 화이트보드에 남겨진 낙서와 공지들. 학과 생활의 평범한 한 장면입니다.",
            latitude: 37.558342, longitude: 126.998353,
            createdAt: "2026-05-28T08:31:24Z"
        ),
        Entry(
            fileName: "IMG_0356.jpeg",
            tags: ["커피", "강의실"],
            description: "캐리어에 담긴 아이스커피 세 잔. 수업 전 나눠 마실 커피를 챙겨온 참입니다.",
            latitude: 37.558472, longitude: 126.998567,
            createdAt: "2026-05-13T05:44:47Z"
        ),
        Entry(
            fileName: "IMG_0275.jpeg",
            tags: ["남산", "전망"],
            description: "남산 산책로에서 내려다본 서울 도심 전경입니다. 초록 숲 너머로 빌딩들이 넓게 펼쳐져 있어요.",
            latitude: 37.551133, longitude: 126.991142,
            createdAt: "2026-05-06T06:52:42Z"
        ),
        Entry(
            fileName: "8146BE25-73DE-4BC5-A48D-D3227D8DBF6F.jpg",
            tags: ["쇼핑", "셀피"],
            description: "선글라스 매장 거울 앞에서 찍은 셀피입니다. 진열된 선글라스 너머로 카메라를 든 모습이 비쳐요.",
            latitude: 37.541370, longitude: 127.059417,
            createdAt: "2026-04-26T08:54:28Z",
            isSensitive: true
        ),
        Entry(
            fileName: "IMG_0099.jpeg",
            tags: ["한강", "여의도"],
            description: "여의도 한강공원에서 바라본 63빌딩과 도심 실루엣. 오후의 역광이 만든 은은한 분위기가 인상적입니다.",
            latitude: 37.517997, longitude: 126.957833,
            createdAt: "2026-04-22T08:36:19Z"
        ),
        Entry(
            fileName: "IMG_9898.jpeg",
            tags: ["벚꽃", "봄"],
            description: "다리 난간 옆으로 벚꽃이 만개했습니다. 파란 하늘과 흰 꽃잎의 대비가 봄 분위기를 그대로 담고 있어요.",
            latitude: 37.557605, longitude: 127.001511,
            createdAt: "2026-04-02T03:46:35Z"
        ),
        Entry(
            fileName: "IMG_9563.jpeg",
            tags: ["강릉", "바다", "겨울바다"],
            description: "강릉 해변의 짙푸른 겨울 바다입니다. 구름 한 점 없는 하늘 아래로 하얀 파도가 밀려오고 있어요.",
            latitude: 37.805705, longitude: 128.908875,
            createdAt: "2026-02-25T03:45:21Z"
        ),
        Entry(
            fileName: "IMG_8415.JPG",
            tags: ["고양이", "길냥이"],
            // GPS 없는 사진 — 상세 화면에서 지도 섹션이 숨겨지는 케이스 확인용
            description: "볕 좋은 잔디밭에 늘어져 낮잠 자는 주황 고양이. 완벽하게 이완된 자세가 귀엽습니다.",
            latitude: 0, longitude: 0,
            createdAt: "2025-11-06T17:10:53Z"
        ),
    ]

    static let isoFormatter = ISO8601DateFormatter()

    static func entry(photoId: Int) -> Entry? {
        guard entries.indices.contains(photoId - 1) else { return nil }
        return entries[photoId - 1]
    }

    /// 배열 index 기준으로 Photo 도메인 모델 생성 (photoId = index + 1)
    static func photo(at index: Int) -> Photo {
        let entry = entries[index]
        return Photo(
            photoId: index + 1,
            imageUrl: imageUrl(fileName: entry.fileName),
            latitude: entry.latitude,
            longitude: entry.longitude,
            createdAt: isoFormatter.date(from: entry.createdAt) ?? Date(),
            fileName: entry.fileName,
            tags: entry.tags,
            isSensitive: entry.isSensitive
        )
    }

    static func imageUrl(fileName: String) -> URL {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        // 동기화 그룹 리소스는 번들 루트로 평탄화되지만, 폴더 참조로 추가된 경우를 대비해 하위 경로도 시도.
        // 둘 다 실패하면 존재하지 않는 파일 URL을 반환해 회색 플레이스홀더가 보이게 함
        return Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "MockImages")
            ?? URL(fileURLWithPath: "/\(fileName)")
    }
}

// MARK: - Mock UseCases

private struct MockGetPhotosUseCase: GetPhotosUseCaseProtocol {
    func execute() async throws -> [Photo] {
        MockPhotoFixtures.entries.indices.map { MockPhotoFixtures.photo(at: $0) }
    }
}

private struct MockUploadPhotosUseCase: UploadPhotosUseCaseProtocol {
    func execute(items: [PhotoUploadItem], onItemUploaded: ((Int) -> Void)?) async throws {
        for index in items.indices {
            try? await Task.sleep(for: .milliseconds(400))
            onItemUploaded?(index + 1)
        }
    }
}

private struct MockExtractPhotoMetadataUseCase: ExtractPhotoMetadataUseCaseProtocol {
    // nil을 반환하면 업로드 파이프라인이 조기 종료되어 진행 배너를 확인할 수 없으므로,
    // 데모에서도 실제 업로드 흐름을 타도록 유효한 아이템을 반환
    func execute(imageData: Data, identifier: String?) async -> PhotoUploadItem? {
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? imageData.write(to: url)
        return PhotoUploadItem(
            latitude: 37.5665,
            longitude: 126.9780,
            imageUrl: url,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            fileName: fileName
        )
    }
}

private struct MockDeletePhotoUseCase: DeletePhotoUseCaseProtocol {
    func execute(photoId: Int) async throws {}
}

private struct MockGetTagsUseCase: GetTagsUseCaseProtocol {
    func execute(photoId: Int) async throws -> [PhotoTag] {
        guard let entry = MockPhotoFixtures.entry(photoId: photoId) else { return [] }
        return entry.tags.enumerated().map { index, name in
            PhotoTag(
                photoTagId: photoId * 10 + index,
                tagId: photoId * 10 + index,
                tagName: name,
                photoId: photoId
            )
        }
    }
}

private struct MockAddTagUseCase: AddTagUseCaseProtocol {
    func execute(photoId: Int, tagName: String) async throws -> PhotoTag {
        // 픽스처 태그 id(photoId*10+index)와 겹치지 않는 범위 사용
        PhotoTag(photoTagId: 9000 + photoId, tagId: 9000 + photoId, tagName: tagName, photoId: photoId)
    }
}

private struct MockDeleteTagUseCase: DeleteTagUseCaseProtocol {
    func execute(photoTagId: Int) async throws {}
}

private struct MockUpdateTagUseCase: UpdateTagUseCaseProtocol {
    func execute(photoTagId: Int, tagName: String) async throws -> PhotoTag {
        PhotoTag(photoTagId: photoTagId, tagId: photoTagId, tagName: tagName, photoId: 1)
    }
}

private struct MockGetDescriptionUseCase: GetDescriptionUseCaseProtocol {
    func execute(photoId: Int) async throws -> String {
        MockPhotoFixtures.entry(photoId: photoId)?.description ?? ""
    }
}
#endif
