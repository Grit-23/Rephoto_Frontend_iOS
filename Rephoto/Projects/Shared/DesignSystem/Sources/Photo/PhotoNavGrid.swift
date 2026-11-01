//
//  PhotoNavGrid.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 8/17/26.
//

import SwiftUI

/// 사진 3열 그리드 공용 컴포넌트 — 타일 탭 시 값 기반 push(NavigationLink)와
/// 사진 상세로의 줌 전환(matchedTransitionSource)까지 포함
/// 좌우 여백 없이(edge-to-edge) 배치하는 것이 기본 — 사진 앱과 같은 밀도
///
/// 도메인 모델(`Photo`)을 직접 받지 않고 항목 타입을 제네릭으로 둔다 — DesignSystem이 Domain을
/// 참조하면 의존성 방향이 역전된다
public struct PhotoNavGrid<Item: Identifiable & Hashable>: View {
    private let items: [Item]
    /// 항목에서 썸네일 URL을 꺼내는 키패스.
    ///
    /// 클로저가 아니라 `KeyPath`로 받는다 — 클로저는 비교가 안 돼 부모 body가 돌 때마다
    /// 이 뷰가 무효화되지만, `KeyPath`는 Equatable이라 입력이 같으면 건너뛴다.
    private let imageUrl: KeyPath<Item, URL>
    private let namespace: Namespace.ID
    private let spacing: CGFloat

    public init(
        items: [Item],
        imageUrl: KeyPath<Item, URL>,
        namespace: Namespace.ID,
        spacing: CGFloat = 2
    ) {
        self.items = items
        self.imageUrl = imageUrl
        self.namespace = namespace
        self.spacing = spacing
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3),
            spacing: spacing
        ) {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    PhotoGridTile(imageUrl: item[keyPath: imageUrl])
                        .matchedTransitionSource(id: item.id, in: namespace)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
