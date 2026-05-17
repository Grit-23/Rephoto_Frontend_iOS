//
//  TagRepositoryProtocol.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import Foundation

protocol TagRepositoryProtocol {
    func getTags(photoId: Int) async throws -> [PhotoTag]
    func addTag(photoId: Int, tagName: String) async throws -> PhotoTag
    func updateTag(photoTagId: Int, tagName: String) async throws -> PhotoTag
    func deleteTag(photoTagId: Int) async throws
}
