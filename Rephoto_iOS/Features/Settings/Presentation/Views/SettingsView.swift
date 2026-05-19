//
//  SettingsView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var sheetDetent: PresentationDetent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
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
    SettingsView(sheetDetent: .constant(.medium))
}
