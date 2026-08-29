//
//  ErrorStateView.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/28/26.
//

import SwiftUI

/// 화면을 채우는 에러 상태 뷰.
///
/// 아이콘·제목·설명은 ``ErrorDisplay``가, 재시도 버튼 노출 여부는 ``AppError/isRetryable``이
/// 결정하므로 호출부는 에러와 재시도 동작만 넘긴다. 재시도 불가능한 에러(4xx·도메인 규칙
/// 위반)에는 버튼이 자동으로 빠진다.
struct ErrorStateView: View {
    let error: AppError
    var onRetry: (() async -> Void)?

    private var display: ErrorDisplay { ErrorDisplay(error) }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: display.systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            Text(display.title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text(display.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if error.isRetryable, let onRetry {
                Button {
                    Task { await onRetry() }
                } label: {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.interactive().tint(.mainGreen), in: Capsule())
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

#if DEBUG
#Preview("오프라인") {
    ErrorStateView(error: .network(.noNetwork)) {}
}

#Preview("재시도 불가") {
    ErrorStateView(error: .repository(.decodingError(detail: "Missing key: imageUrl"))) {}
}
#endif
