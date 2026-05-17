import Foundation

struct AlbumTagDTO: Codable, Equatable {
    let tagId: Int
    let tagName: String
}

struct Album: Codable, Equatable {
    let user: User
    let tag: AlbumTagDTO
}
