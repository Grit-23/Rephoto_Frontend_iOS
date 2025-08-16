
// DTOs/Photos/PhotoBatchRequestDto.swift
import Foundation

public struct PhotoBatchRequestDto: Codable {
    public let photos: [PhotoMetadata]
}
