//
//  PhotoInfoView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import NukeUI

struct PhotoInfoView: View {
    let photo: Photo
    @State private var vm: PhotoInfoViewModel
    @State private var showDeleteConfirmation = false
    @State private var tagSheetMode: TagSheetMode?
    @Namespace private var tagZoom
    @Environment(\.dismiss) private var dismiss

    init(photo: Photo, provider: HomeUseCaseProviderProtocol) {
        self.photo = photo
        self._vm = State(initialValue: PhotoInfoViewModel(provider: provider))
    }

    var body: some View {
        // 기본 사진 앱처럼 사진 아래에 태그·AI 설명·정보·지도가 한 흐름으로 이어짐
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PhotoHeroImage(imageUrl: photo.imageUrl)

                TagSection(
                    tags: vm.tags,
                    namespace: tagZoom,
                    onTapTag: { tagSheetMode = .edit($0) },
                    onTapAdd: { tagSheetMode = .add }
                )
                .padding(.horizontal, 20)

                if !vm.description.isEmpty {
                    AIDescriptionCard(text: vm.description)
                        .padding(.horizontal, 16)
                }

                FileInfoSection(fileName: photo.fileName, createdAt: photo.createdAt)
                    .padding(.horizontal, 16)

                if photo.latitude != 0 || photo.longitude != 0 {
                    LocationMapSection(latitude: photo.latitude, longitude: photo.longitude)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: photo.imageUrl)
                    .tint(.primary)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
        .confirmationDialog("사진을 삭제하시겠습니까?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                Task {
                    await vm.deletePhoto(photoId: photo.photoId)
                }
            }
        }
        .sheet(item: $tagSheetMode) { mode in
            TagEditorSheet(mode: mode) { name in
                Task {
                    switch mode {
                    case .add:
                        await vm.addTag(photoId: photo.photoId, tagName: name)
                    case .edit(let tag):
                        await vm.updateTag(photoTagId: tag.photoTagId, newTagName: name)
                    }
                }
            } onDelete: {
                if case .edit(let tag) = mode {
                    Task { await vm.deleteTag(photoTagId: tag.photoTagId) }
                }
            }
            // 탭한 태그 칩(또는 + 버튼)에서 시트가 확대되어 나오는 줌 전환
            .navigationTransition(.zoom(sourceID: mode.id, in: tagZoom))
        }
        .task {
            // 태그와 AI 설명은 서로 독립이므로 병렬 로드
            async let tags: Void = vm.fetchTags(photoId: photo.photoId)
            async let description: Void = vm.getDescription(photoId: photo.photoId)
            _ = await (tags, description)
        }
        .onChange(of: vm.isDeleted) { _, isDeleted in
            if isDeleted { dismiss() }
        }
    }
}

// MARK: - PhotoHeroImage

private struct PhotoHeroImage: View {
    let imageUrl: URL

    var body: some View {
        LazyImage(url: imageUrl) { state in
            if let image = state.image {
                image
                    .resizable()
                    // fit: 원본 비율 유지 — 사진이 잘리지 않도록 함
                    .scaledToFit()
            } else {
                Color.gray.opacity(0.2)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

#if DEBUG
#Preview("PhotoInfo") {
    NavigationStack {
        PhotoInfoView(
            photo: Photo(
                photoId: 1,
                imageUrl: URL(string: "https://picsum.photos/seed/detail/800/1200")!,
                latitude: 37.5665,
                longitude: 126.9780,
                createdAt: Date(),
                fileName: "IMG_0412.jpg",
                tags: ["바다", "풍경"],
                isSensitive: false
            ),
            provider: MockHomeUseCaseProvider()
        )
    }
}
#endif
