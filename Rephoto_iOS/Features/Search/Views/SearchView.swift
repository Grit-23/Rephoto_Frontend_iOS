//
//  SearchView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import NukeUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let side = geo.size.width / 2 - 16
                let cols = Array(repeating: GridItem(.fixed(side), spacing: 8), count: 2)

                ScrollView {
                    if vm.isLoading {
                        ProgressView("검색 중…")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else if vm.searchResults.isEmpty {
                        Text("검색 결과가 없습니다.")
                            .padding()
                    }

                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(vm.searchResults) { item in
                            LazyImage(url: item.imageUrl) { state in
                                if let image = state.image {
                                    NavigationLink {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                    } label: {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: side, height: side)
                                            .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else {
                                    Color.gray
                                        .frame(width: side, height: side)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                .searchable(text: $vm.query, prompt: "사진을 검색해보세요!")
            }
        }
    }
}
