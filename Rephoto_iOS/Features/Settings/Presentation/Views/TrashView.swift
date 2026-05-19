//
//  TrashView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/10/25.
//

import SwiftUI

struct TrashView: View {
    @Binding var sheetDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            Text("TrashView")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    sheetDetent = .medium
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .tint(.black)
    }
}

#Preview {
    TrashView(sheetDetent: .constant(.medium))
}
