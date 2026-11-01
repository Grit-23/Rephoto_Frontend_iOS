//
//  MultipartFormItem.swift
//  NetworkAdapter
//
//  Created by Doyeon Kim on 7/15/26.
//

import Foundation

/// multipart/form-data의 개별 파트
public struct MultipartFormItem: Sendable {
    public let data: Data
    public let name: String
    public let fileName: String?
    public let mimeType: String?

    public init(data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
