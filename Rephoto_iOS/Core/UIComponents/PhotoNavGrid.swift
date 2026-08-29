//
//  PhotoNavGrid.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 8/17/26.
//

import SwiftUI

/// 사진 3열 그리드 공용 컴포넌트 — 타일 탭 시 값 기반 push(NavigationLink)와
/// 사진 상세로의 줌 전환(matchedTransitionSource)까지 포함
/// 좌우 여백 없이(edge-to-edge) 배치하는 것이 기본 — 사진 앱과 같은 밀도
///
/// 도메인 모델(`Photo`)을 직접 받지 않고 항목 타입을 제네릭으로 둔다 — Core가 Feature를
/// 참조하면 의존성 방향이 역전되고, Step 4 멀티모듈 분리에서 Core↔Feature 순환이 된다
struct PhotoNavGrid<Item: Identifiable & Hashable>: View {
    let items: [Item]
    /// 항목에서 썸네일 URL을 꺼내는 방법 — 호출부에서 키패스(`\.imageUrl`)로 넘긴다
    let imageUrl: (Item) -> URL
    let namespace: Namespace.ID
    var spacing: CGFloat = 2

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3),
            spacing: spacing
        ) {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    PhotoGridTile(imageUrl: imageUrl(item))
                        .matchedTransitionSource(id: item.id, in: namespace)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
