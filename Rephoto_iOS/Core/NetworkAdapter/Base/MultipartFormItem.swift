//
//  MultipartFormItem.swift
//  Rephoto_iOS
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

/// multipart/form-data의 개별 파트
struct MultipartFormItem {
    let data: Data
    let name: String
    let fileName: String?
    let mimeType: String?

    init(data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
