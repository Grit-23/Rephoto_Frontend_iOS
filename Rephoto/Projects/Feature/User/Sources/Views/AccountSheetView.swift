//
//  AccountSheetView.swift
//  UserFeature
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI
import DesignSystem

public struct AccountSheetView: View {
    @Environment(\.dismiss) private var dismiss
    private let session: SessionStore

    @State private var showLogoutConfirmation = false

    public init(session: SessionStore) {
        self.session = session
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProfileCard(name: session.name)

                VersionRow(version: appVersion)

                Spacer()
                
                LogoutCard {
                    showLogoutConfirmation = true
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .background(Color.base.ignoresSafeArea())
            .navigationTitle("내 정보")
            .navigationBarTitleDisplayMode(.inline)
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
        .presentationDetents([.medium])
    }
}

private struct VersionRow: View {
    let version: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "info")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.labelSecondary)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                .frame(width: 52)

            Text("버전")
                .font(.system(size: 17))
                .foregroundStyle(.labelPrimary)

            Spacer()

            Text(version)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.labelTertiary)
        }
    }
}
