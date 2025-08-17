//
//  PhotoInfoView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/14/25.
//

import SwiftUI
import NukeUI
struct PhotoInfoView : View {
    let photo: HomeModel
    
    @State private var vm = PhotoInfoViewModel()
    @State private var showDeleteConfirm = false
    @State private var showTagEdit = false
    @State private var selectedTag: TagResponseDto? = nil
    @State private var newTagName: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            LazyImage(url: photo.imageUrl) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                }
            }
            infoSection
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(.black)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
        .confirmationDialog("삭제하시겠습니까?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                vm.deletePhoto(photoId: photo.photoId)
            }
        }
        .task {
            vm.fetchTags(photoId: photo.photoId)   // ✅ 상세 태그 조회
        }
        .alert("태그 수정", isPresented: $showTagEdit) {
            TextField("새 태그명", text: $newTagName)
            Button("확인") {
                if let tag = selectedTag {
                    vm.updateTag(photoTagId: tag.photoTagId, newTagName: newTagName)
                } else {
                    vm.addTag(photoId: photo.photoId, tagName: newTagName)
                }
            }
            Button("취소", role: .cancel) { }
        }
        .onChange(of: vm.isDeleted) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    var infoSection: some View {
        // ✅ 상세 태그가 있으면 그걸, 없으면 HomeModel의 문자열 태그를 보여줌
        let displayTags: [TagResponseDto] =
        vm.tags.isEmpty
        ? photo.tags.enumerated().map { (idx, name) in
            TagResponseDto(photoTagId: idx, tagId: idx, tagName: name, photoId: photo.photoId)
        }
        : vm.tags
        
        return HStack {
            ForEach(displayTags, id: \.photoTagId) { tag in
                Text("#\(tag.tagName)")
                    .font(.title3)
                    .bold()
                    .padding()
                    .glassEffect()
                    .onTapGesture {
                        selectedTag = tag
                        newTagName = tag.tagName
                        showTagEdit = true
                    }
            }
            if displayTags.count < 3 {
                Text("태그 추가")
                    .font(.title3)
                    .bold()
                    .padding()
                    .glassEffect()
                    .onTapGesture {
                        showTagEdit = true
                    }
            }
        }
    }
}

#Preview {
    let dummyPhoto = HomeModel(
        photoId: 1,
        imageUrl: URL(string: "https://picsum.photos/300")!, // 샘플 이미지 URL
        latitude: 37.5665,
        longitude: 126.9780,
        createdAt: Date(),
        fileName: "sample_photo.jpg",
        tags: ["감자", "고구마", "치즈"],
        isSensitive: false
    )
    
    return NavigationStack {
        PhotoInfoView(photo: dummyPhoto)
    }
}
