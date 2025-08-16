//
//  PhotoInfoViewModel.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/14/25.
//

import SwiftUI
import Moya
import Observation

@Observable
class PhotoInfoViewModel {
    private let provider = MoyaProvider<PhotosAPITarget>()
    var isDeleted: Bool = false   // 삭제 완료 여부
    
    func deletePhoto(photoId: Int) {
        provider.request(.deletePhoto(photoId: photoId)) { result in
            switch result {
            case .success(let response):
                if (200..<300).contains(response.statusCode) {
                    DispatchQueue.main.async {
                        self.isDeleted = true
                    }
                } else {
                    print("삭제 실패 statusCode:", response.statusCode)
                }
            case .failure(let error):
                print("삭제 네트워크 에러:", error)
            }
        }
    }
}
