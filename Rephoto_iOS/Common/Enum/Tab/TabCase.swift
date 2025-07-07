//
//  TabCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import Foundation
import SwiftUI

enum TabCase: String, CaseIterable {
    case home = "Home"
    case map = "Map"
    case search = "Search"
    
    var icon: Image {
        switch self {
        case .home:
            return .init(.home)
        case .map:
            return .init(.map)
        case .search:
            return .init(.search)
        }
    }
}
