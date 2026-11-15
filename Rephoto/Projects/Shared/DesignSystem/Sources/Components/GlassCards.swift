//
//  GlassCards.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 7/24/26.
//

import SwiftUI

// MARK: - ProfileCard

/// 글래스 아바타(이름 첫 글자) + 이름 — 내 정보 시트
public struct ProfileCard: View {
    private let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        HStack(spacing: 14) {
            Text(name.prefix(1))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .glassEffect(.regular.tint(.mainGreen), in: Circle())

            Text(name)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.labelPrimary)

            Spacer()
        }
    }
}

// MARK: - LogoutCard

/// 로그아웃 글래스 카드 버튼 — 내 정보 시트
public struct LogoutCard: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text("로그아웃")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0xE2 / 255, green: 0x33 / 255, blue: 0x2F / 255))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        ProfileCard(name: "김도연")
        LogoutCard {}
    }
    .padding(22)
    .background(Color.base)
}
#endif
