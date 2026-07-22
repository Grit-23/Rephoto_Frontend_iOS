//
//  HomeView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var vm: HomeViewModel
    @State private var showUserSheet = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @Namespace private var photoZoom

    init(provider: HomeUseCaseProviderProtocol) {
        self._vm = State(initialValue: HomeViewModel(provider: provider))
    }

    var body: some View {
        @Bindable var vm = vm
        return NavigationStack {
            Group {
                if vm.isLoading && vm.photos.isEmpty {
                    PhotoGridSkeletonView()
                } else if vm.errorMessage != nil && vm.photos.isEmpty {
                    HomeErrorStateView {
                        Task { await vm.fetchPhotos() }
                    }
                } else if vm.photos.isEmpty {
                    HomeEmptyStateView(selection: $selectedPickerItems)
                } else {
                    PhotoGridView(
                        photos: vm.visiblePhotos,
                        sensitiveCount: vm.sensitiveCount,
                        namespace: photoZoom
                    )
                }
            }
            .navigationTitle("앨범")
            .navigationDestination(for: Photo.self) { photo in
                PhotoInfoView(photo: photo, provider: vm.provider)
                    // 그리드 타일에서 사진이 확대되어 튀어나오는 줌 전환
                    .navigationTransition(.zoom(sourceID: photo.photoId, in: photoZoom))
            }
            .navigationDestination(for: SensitivePhotosRoute.self) { _ in
                SensitivePhotosView(photos: vm.sensitivePhotos, namespace: photoZoom)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showUserSheet = true
                    } label: {
                        Image(systemName: "person.fill")
                    }
                    .tint(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedPickerItems,
                        matching: .images
                    ) {
                        Image(systemName: "plus")
                    }
                    .tint(.primary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let progress = vm.uploadProgress {
                    UploadProgressBanner(progress: progress)
                }
            }
            .task {
                await vm.fetchPhotos()
            }
            .sheet(isPresented: $showUserSheet) {
                HomeSheetView()
            }
            .onChange(of: selectedPickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    await vm.handlePickedPhotos(items)
                    selectedPickerItems = []
                }
            }
            .alert("오류", isPresented: $vm.isShowingErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}

// MARK: - PhotoGridView

private struct PhotoGridView: View {
    let photos: [Photo]
    let sensitiveCount: Int
    let namespace: Namespace.ID

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if sensitiveCount > 0 {
                    NavigationLink(value: SensitivePhotosRoute()) {
                        SensitiveChip(count: sensitiveCount)
                    }
                }

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoGridTile(imageUrl: photo.imageUrl)
                                .matchedTransitionSource(id: photo.photoId, in: namespace)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SensitiveChip

private struct SensitiveChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("민감한 사진 \(count)장은 숨겨져 있어요")
                .font(.footnote)
            Image(systemName: "chevron.right")
                .font(.caption2)
        }
        // NavigationLink 라벨은 foreground가 액센트가 되므로, 계층적 .secondary 대신
        // 구체 색상을 지정해 틴트가 번지지 않게 함
        .foregroundStyle(Color.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
    }
}

#if DEBUG
#Preview("Home") {
    HomeView(provider: MockHomeUseCaseProvider())
}
#endif
