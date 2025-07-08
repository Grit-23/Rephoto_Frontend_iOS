//
//  SheetCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import Foundation
import SwiftUI

enum HomeSheetCase: String, CaseIterable {
    case upload = "Upload"
    case share = "Share"
    case trash = "Trash"
    case help = "Help"
    case logout = "Logout"
    
    var icon: Image {
        switch self {
        case .upload:
            return Image(systemName: "photo")
        case .share:
            return Image(systemName: "square.and.arrow.up")
        case .trash:
            return Image(systemName: "trash")
        case .help:
            return Image(systemName: "questionmark.circle")
        case .logout:
            return Image(systemName: "escape")
        }
    }
    
    var color: Color {
        switch self {
        case .logout:
            return .red
        default :
            return .black
        }
    }
}
