//
//  AlbumViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 8/19/25.
//

import SwiftUI
import Moya
import Observation
import Factory

@Observable
class AlbumViewModel {
    @ObservationIgnored
    @Injected(\.albumProvider) private var provider

    var albums: [AlbumResponseDto] = []
    var albumInfo: [[Photo]] = []   // ← 빈 배열로 시작

    // 앨범 리스트 호출
    func fetchAlbums() {
        provider.request(.getAlbumList) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([AlbumResponseDto].self, from: response.data)
                    DispatchQueue.main.async {
                        self.albums = dtos
                        // 앨범 수만큼 슬롯 미리 만들기
                        self.albumInfo = Array(repeating: [], count: dtos.count)
                        self.getAlbumInfos()
                    }
                } catch {
                    self.albums.removeAll()
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }

    // 특정 인덱스 슬롯에 넣기
    private func getAlbumInfo(tagId: Int, slot index: Int) {
        provider.request(.getAlbumInfo(tagId: tagId)) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([PhotoResponseDTO].self, from: response.data)
                    let mapped = try dtos.map { try $0.toDomain() }
                    DispatchQueue.main.async {
                        if index < self.albumInfo.count {
                            self.albumInfo[index] = mapped
                        }
                    }
                } catch {
                    print("❌ decode error:", error)
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }

    // 단순 반복문으로 모두 호출(인덱스 동반)
    func getAlbumInfos() {
        for (idx, album) in albums.enumerated() {
            getAlbumInfo(tagId: album.tagId, slot: idx)
        }
    }
}
