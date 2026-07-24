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
                ProfileCard(name: session.name, showsChevron: true)

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

#if DEBUG
#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environment(SessionStore(provider: MockUserUseCaseProvider()))
    }
}
#endif
