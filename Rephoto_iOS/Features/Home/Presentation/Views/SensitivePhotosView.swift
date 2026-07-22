//
//  SensitivePhotosView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI
import LocalAuthentication

/// Home → 민감한 사진 화면 진입용 값 기반 네비게이션 라우트
struct SensitivePhotosRoute: Hashable {}

struct SensitivePhotosView: View {
    let photos: [Photo]
    let namespace: Namespace.ID

    @State private var isUnlocked = false
    @State private var authErrorMessage: String?
    @Environment(\.scenePhase) private var scenePhase

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SensitiveInfoCard(count: photos.count, isUnlocked: isUnlocked)
                    .padding(.horizontal, 16)

                // 잠금/해제 분기를 ForEach 바깥에 두면 lazy 컨테이너가 캐시한 분기가
                // 갱신되지 않는 문제가 있어, 행 identity는 유지하고 타일 내부에서 전환한다
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photos) { photo in
                        SensitiveTile(photo: photo, isUnlocked: isUnlocked, namespace: namespace)
                    }
                }
            }
        }
        .navigationTitle("민감한 사진")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isUnlocked {
                CTAButton(title: "Face ID로 잠금 해제", isLoading: false) {
                    Task { await authenticate() }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // 백그라운드 진입 시 자동 재잠금
            if phase == .background {
                isUnlocked = false
            }
        }
        .alert("잠금 해제 실패", isPresented: authAlertBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(authErrorMessage ?? "")
        }
    }

    private var authAlertBinding: Binding<Bool> {
        Binding(
            get: { authErrorMessage != nil },
            set: { if !$0 { authErrorMessage = nil } }
        )
    }

    private func authenticate() async {
        let context = LAContext()
        var error: NSError?
        // Face ID 미지원/미등록 기기는 패스코드로 폴백되도록 .deviceOwnerAuthentication 사용
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            #if targetEnvironment(simulator)
            // 시뮬레이터에 인증 수단(Face ID 등록·패스코드)이 없으면 데모용으로 바로 해제.
            // Face ID 테스트: Simulator 메뉴 Features > Face ID > Enrolled 후 Matching Face
            withAnimation { isUnlocked = true }
            #else
            authErrorMessage = error?.localizedDescription ?? "이 기기에서는 인증을 사용할 수 없어요"
            #endif
            return
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "숨겨진 민감한 사진을 보려면 인증이 필요해요"
            )
            if success {
                withAnimation {
                    isUnlocked = true
                }
            }
        } catch let laError as LAError where laError.code == .userCancel || laError.code == .appCancel || laError.code == .systemCancel {
            // 사용자/시스템 취소는 에러로 표시하지 않음
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - SensitiveInfoCard

private struct SensitiveInfoCard: View {
    let count: Int
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 20))
                .foregroundStyle(.mainGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("민감한 사진 \(count)장")
                    .font(.subheadline.weight(.semibold))
                Text(isUnlocked ? "뒤로 가면 자동으로 다시 잠겨요" : "홈에서 자동으로 숨겨져 있어요")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SensitiveTile

/// 잠금 여부에 따라 내용만 바뀌는 단일 타일 — 행 identity가 유지되어 잠금 해제 시 제자리에서 전환됨
private struct SensitiveTile: View {
    let photo: Photo
    let isUnlocked: Bool
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            if isUnlocked {
                NavigationLink(value: photo) {
                    PhotoGridTile(imageUrl: photo.imageUrl)
                        .matchedTransitionSource(id: photo.photoId, in: namespace)
                }
            } else {
                // 잠금 상태에서는 이미지를 로드하지 않음 (프라이버시 보호)
                LockedPhotoTile()
            }
        }
    }
}

// MARK: - LockedPhotoTile

private struct LockedPhotoTile: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
    }
}

#if DEBUG
#Preview("Sensitive - 잠금") {
    @Previewable @Namespace var namespace
    NavigationStack {
        SensitivePhotosView(photos: (1...4).map { i in
            Photo(
                photoId: i,
                imageUrl: URL(string: "https://picsum.photos/seed/sensitive-\(i)/400")!,
                latitude: 37.5665,
                longitude: 126.9780,
                createdAt: Date(),
                fileName: "photo_\(i).jpg",
                tags: [],
                isSensitive: true
            )
        }, namespace: namespace)
    }
}
#endif
