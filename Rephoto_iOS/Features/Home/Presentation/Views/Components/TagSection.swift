//
//  TagSection.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/17/26.
//

import SwiftUI

/// 사진 상세의 태그 칩 목록 + 추가 버튼. 칩/버튼은 태그 편집 시트 줌 전환의 source가 됨
struct TagSection: View {
    let tags: [PhotoTag]
    let namespace: Namespace.ID
    let onTapTag: (PhotoTag) -> Void
    let onTapAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("태그")
                .font(.title3.bold())

            FlowLayout(spacing: 10) {
                ForEach(tags) { tag in
                    Button {
                        onTapTag(tag)
                    } label: {
                        Text(tag.tagName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.mainGreen)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .glassEffect(.regular.interactive().tint(.mainGreen.opacity(0.15)), in: Capsule())
                    }
                    .matchedTransitionSource(id: tag.photoTagId, in: namespace)
                }

                if tags.count < 3 {
                    Button(action: onTapAdd) {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 42, height: 42)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }
                    // TagSheetMode.add의 id(-1)와 매칭
                    .matchedTransitionSource(id: -1, in: namespace)
                }
            }
        }
    }
}
