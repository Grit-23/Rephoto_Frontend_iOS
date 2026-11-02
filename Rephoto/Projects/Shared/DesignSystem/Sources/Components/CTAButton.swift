//
//  CTAButton.swift
//  DesignSystem
//
//  Created by 김도연 on 7/2/26.
//

import SwiftUI

/// 화면 하단의 주 동작 버튼 — 로그인 · 회원가입 · 업로드 공용
public struct CTAButton: View {
    private let title: LocalizedStringResource
    private let isLoading: Bool
    private let action: () -> Void

    public init(title: LocalizedStringResource, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Capsule()
                    .frame(height: 56)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16))
                        .bold()
                        .foregroundStyle(.white)
                }
            }
        }
        .foregroundStyle(.mainGreen)
        .glassEffect(.regular.interactive().tint(.mainGreen), in: Capsule())
        .disabled(isLoading)
    }
}

#if DEBUG
#Preview {
    VStack {
        CTAButton(title: "hello", isLoading: false) {
            print("action")
        }
        CTAButton(title: "hello", isLoading: true) {
            print("action")
        }
    }
}
#endif
