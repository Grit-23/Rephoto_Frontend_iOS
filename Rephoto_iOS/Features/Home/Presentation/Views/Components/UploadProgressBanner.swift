//
//  UploadProgressBanner.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI

/// 사진 업로드 진행 상태를 표시하는 하단 글래스 배너 ("사진 업로드 중… n / m")
struct UploadProgressBanner: View {
    let progress: HomeViewModel.UploadProgress

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("사진 업로드 중…")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(progress.completed) / \(progress.total)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(progress.completed), total: Double(max(progress.total, 1)))
                .tint(.mainGreen)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
