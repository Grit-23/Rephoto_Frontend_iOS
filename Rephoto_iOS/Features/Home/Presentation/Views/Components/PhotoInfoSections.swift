//
//  PhotoInfoSections.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI
import MapKit

// MARK: - AIDescriptionCard

/// AI가 생성한 사진 설명 글래스 카드
struct AIDescriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.footnote)
                Text("AI 설명")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.mainGreen)

            Text(text)
                .font(.subheadline)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - FileInfoSection

/// 파일명·촬영일 정보 글래스 카드
struct FileInfoSection: View {
    let fileName: String
    let createdAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정보")
                .font(.title3.bold())
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                LabeledContent("파일명", value: fileName)
                    .padding(.vertical, 12)
                Divider()
                LabeledContent("촬영일") {
                    Text(createdAt, format: .dateTime.year().month().day().hour().minute())
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - LocationMapSection

/// 촬영 위치를 지도 핀으로 표시하는 섹션
struct LocationMapSection: View {
    let latitude: Double
    let longitude: Double

    var body: some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        VStack(alignment: .leading, spacing: 12) {
            Text("위치")
                .font(.title3.bold())
                .padding(.horizontal, 4)

            Map(initialPosition: .region(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
            )) {
                Marker("촬영 위치", systemImage: "camera.fill", coordinate: coordinate)
                    .tint(.mainGreen)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // 스크롤과 충돌하지 않도록 지도 제스처 비활성화
            .allowsHitTesting(false)
        }
    }
}
