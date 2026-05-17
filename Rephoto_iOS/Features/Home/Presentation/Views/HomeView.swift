//
//  HomeView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import NukeUI

struct HomeView: View {
    @State var vm: HomeViewModel
    @State private var showPhotoPicker = false
    @State private var showUserSheet = false
    @State private var selectedPhotoItems: [PhotoUploadItem] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    init(provider: HomeUseCaseProviderProtocol) {
        self._vm = State(initialValue: HomeViewModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(vm.visiblePhotos) { photo in
                        NavigationLink(value: photo) {
                            LazyImage(url: photo.imageUrl) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(minHeight: 120)
                            .clipped()
                        }
                    }
                }
            }
            .navigationTitle("앨범")
            .navigationDestination(for: Photo.self) { photo in
                PhotoInfoView(photo: photo, provider: vm.provider)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showUserSheet = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await vm.fetchPhotos()
            }
            .sheet(isPresented: $showUserSheet) {
                HomeSheetView()
            }
            .sheet(isPresented: $showPhotoPicker) {
                PHCaptureImageView(photos: $selectedPhotoItems)
            }
            .onChange(of: selectedPhotoItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    await vm.uploadPhotos(items: items)
                    selectedPhotoItems = []
                }
            }
        }
    }
}
