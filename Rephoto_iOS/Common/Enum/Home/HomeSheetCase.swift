//
//  SheetCase.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import Foundation
import SwiftUI

enum HomeSheetCase: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
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
    
    var detent: PresentationDetent {
        switch self {
        case .logout:
            return .medium
        default :
            return .large
        }
    }
    
    @ViewBuilder
    func destinationView(sheetDetent: Binding<PresentationDetent>) -> some View {
        switch self {
        case .upload:
            UploadView(sheetDetent: sheetDetent)
        case .share:
            ShareView(sheetDetent: sheetDetent)
        case .trash:
            TrashView(sheetDetent: sheetDetent)
        case .help:
            HelpView(sheetDetent: sheetDetent)
        case .logout:
            Color.red
        }
    }
}
