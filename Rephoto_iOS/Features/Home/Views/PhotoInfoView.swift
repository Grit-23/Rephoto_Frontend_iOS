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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyImage(url: photo.imageUrl) { state in
                    if let image = state.image {
                        image
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    }
                }
                .padding()
                
                infoSection
                buttons
            }
            .padding()
        }
        .navigationTitle("사진 정보")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            Button("취소", role: .cancel) { }
        }
        .onChange(of: vm.isDeleted) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("파일명: \(photo.fileName)")
                .font(.headline)
            Text("업로드 날짜: \(photo.createdAt.formatted(date: .abbreviated, time: .shortened))")
            Text("위치: 위도 \(photo.latitude), 경도 \(photo.longitude)")
            ForEach(photo.tags, id: \.self) { tag in
                Text("태그 : \(tag)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
    }
    
    var buttons : some View {
        HStack(spacing: 20){
            Button {
                // TODO: 태그 수정 기능
            } label: {
                Text("태그 수정")
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.color6)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
            }
            Button {
                // TODO: 사진 공유 기능
            } label: {
                Text("사진 공유")
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.color6)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
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
