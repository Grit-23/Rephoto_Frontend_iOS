//
//  HomeSheetView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI

struct HomeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var showSettings = false
    @State private var showLogoutConfirmation = false
    @State private var sheetDetent: PresentationDetent = .medium

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ProfileCard(name: session.name)

                SettingsLinkRow {
                    // 설정은 전체 높이가 필요하므로 push와 함께 시트를 확장
                    sheetDetent = .large
                    showSettings = true
                }

                LogoutCard {
                    showLogoutConfirmation = true
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .background(Color.base.ignoresSafeArea())
            .navigationTitle("내 정보")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .confirmationDialog("로그아웃하시겠습니까?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("로그아웃", role: .destructive) {
                    Task { await session.logout() }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $sheetDetent)
        .onChange(of: showSettings) { _, isShowing in
            // 설정에서 돌아오면 시트를 원래 높이로 복귀
            if !isShowing { sheetDetent = .medium }
        }
    }
}

// MARK: - SettingsLinkRow

/// 설정 화면으로 이동하는 글래스 행 (그린 아이콘 타일 + chevron)
private struct SettingsLinkRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        Color(red: 0x5B / 255, green: 0x8C / 255, blue: 0x63 / 255),
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                Text("설정")
                    .font(.system(size: 17))
                    .foregroundStyle(.labelPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.labelTertiary)
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .frame(height: 56)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("HomeSheet") {
    Text("Home")
        .sheet(isPresented: .constant(true)) {
            HomeSheetView()
                .environment(SessionStore(provider: MockUserUseCaseProvider()))
        }
}
#endif
