//
//  SettingsView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var session
    @State private var showLogoutConfirmation = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsProfileCard(name: session.name)

                Text("정보")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.labelSecondary)
                    .padding(.leading, 12)
                    .padding(.top, 28)
                    .padding(.bottom, 10)

                VersionRow(version: appVersion)

                LogoutCard {
                    showLogoutConfirmation = true
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.base.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("로그아웃하시겠습니까?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) {
                Task { await session.logout() }
            }
        }
    }
}

// MARK: - SettingsProfileCard

/// 아바타(이름 첫 글자) + 이름 글래스 프로필 카드
private struct SettingsProfileCard: View {
    let name: String

    var body: some View {
        HStack(spacing: 14) {
            Text(name.prefix(1))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [.lightGreen, .mainGreen], startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )

            Text(name)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.labelPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.labelTertiary)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .frame(height: 80)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - VersionRow

/// 앱 버전 정보 글래스 행
private struct VersionRow: View {
    let version: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Color(red: 0x9A / 255, green: 0xA0 / 255, blue: 0xA6 / 255),
                    in: RoundedRectangle(cornerRadius: 8)
                )

            Text("버전")
                .font(.system(size: 17))
                .foregroundStyle(.labelPrimary)

            Spacer()

            Text(version)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.labelTertiary)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.labelTertiary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(height: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - LogoutCard

/// 로그아웃 글래스 카드 버튼
private struct LogoutCard: View {
    let action: () -> Void

    var body: some View {
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
#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environment(SessionStore(provider: MockUserUseCaseProvider()))
    }
}
#endif
