//
//  SearchFeatureExampleApp.swift
//  SearchFeatureExample
//
//  Created by Doyeon Kim on 11/10/26.
//

import SwiftUI
import SearchFeature

/// SearchFeature만 단독으로 띄워 확인하는 앱. 서버 대신 PreviewSupport의 메모리 Repository를 쓴다.
/// 앨범 목록 · 앨범 사진 · 검색(디바운스 · 빈 결과) · 사진 상세 연결을 여기서 확인한다.
/// 사진 상세는 Home 구현 없이 대체 화면으로 띄운다.
@main
struct SearchFeatureExampleApp: App {
    private let provider = ExampleSearchProvider()
    private let photoDetail = ExamplePhotoDetailBuilder()
    @State private var query = ""

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("검색", systemImage: "magnifyingglass", role: .search) {
                    SearchView(provider: provider, photoDetail: photoDetail, query: query)
                }
            }
            .searchable(text: $query, prompt: "사진을 검색해보세요!")
        }
    }
}
