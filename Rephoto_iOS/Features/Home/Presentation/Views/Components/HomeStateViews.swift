//
//  HomeStateViews.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI
import PhotosUI

// MARK: - PhotoGridSkeletonView

/// 초기 로딩 중 표시되는 그리드 스켈레톤 (펄스 애니메이션)
struct PhotoGridSkeletonView: View {
    @State private var pulse = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<15, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .opacity(pulse ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        }
        .scrollDisabled(true)
        .onAppear { pulse = true }
    }
}

// MARK: - HomeEmptyStateView

struct HomeEmptyStateView: View {
    @Binding var selection: [PhotosPickerItem]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            Text("아직 사진이 없어요")
                .font(.title3.bold())
            Text("갤러리에서 사진을 추가해\n위치·태그와 함께 기록해보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PhotosPicker(selection: $selection, matching: .images) {
                Label("사진 추가", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.interactive().tint(.mainGreen), in: Capsule())
            }
            .padding(.top, 12)
        }
        .padding(32)
    }
}

// 에러 상태 뷰는 Core/UIComponents/ErrorStateView로 승격됨 —
// AppError가 아이콘·문구·재시도 버튼 유무를 스스로 결정하므로 화면별 사본이 필요 없다
