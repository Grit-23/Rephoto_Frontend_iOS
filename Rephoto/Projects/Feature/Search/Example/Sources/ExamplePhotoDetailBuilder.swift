//
//  ExamplePhotoDetailBuilder.swift
//  SearchFeatureExample
//
//  Created by Doyeon Kim on 11/10/26.
//

import SwiftUI
import DesignSystem
import HomeFeatureInterface
import PhotoDomainInterface

/// Home 구현 없이 사진 상세 자리를 채우는 대체 화면. Search → 상세 연결이 됐는지만 확인한다.
struct ExamplePhotoDetailBuilder: PhotoDetailBuilding {
    func makePhotoDetail(photo: Photo) -> AnyView {
        AnyView(ExamplePhotoDetailView(photo: photo))
    }
}

private struct ExamplePhotoDetailView: View {
    let photo: Photo

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 44))
                .foregroundStyle(.mainGreen)
            Text("사진 #\(photo.photoId)")
                .font(.title2.bold())
            Text(photo.fileName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("App에서는 Home의 사진 상세가 열린다")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.base.ignoresSafeArea())
        .navigationTitle("사진 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}
