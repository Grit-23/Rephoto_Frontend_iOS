//
//  HomeViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import Moya
import Observation

@Observable
class HomeViewModel {
    var images: [HomeModel] = []
    
    var isWarningsCount: Int {
        images.count(where: { $0.isSensitive })
    }
    
    private let provider = MoyaProvider<PhotosAPITarget>()
    
    init() {
        fetchPhotos()
    }
    
    // 사진 불러오기
    func fetchPhotos() {
        provider.request(.getAllPhotos) { result in
            switch result {
            case .success(let response):
                do {
                    let dtos = try JSONDecoder().decode([PhotoResponseDto].self, from: response.data)
                    let mapped = dtos.map { $0.toHomeModel() }
                    DispatchQueue.main.async {
                        self.images = mapped
                    }
                } catch {
                    print("❌ decode error:", error)
                    if let raw = String(data: response.data, encoding: .utf8) {
                        print("📄 raw response:", raw)
                    }
                }
            case .failure(let error):
                print("❌ network error:", error)
            }
        }
    }
}
