//
//  CTAButton.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/2/26.
//

import SwiftUI

struct CTAButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .frame(height: 56)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16))
                        .bold()
                        .foregroundStyle(.white)
                }
            }
        }
        .foregroundStyle(.mainGreen)
        .glassEffect(.regular.interactive().tint(.mainGreen), in: RoundedRectangle(cornerRadius: 16))
        .disabled(isLoading)
    }
}

#Preview {
    VStack {
        CTAButton(title: "hello", isLoading: false) {
            print("action")
        }
        CTAButton(title: "hello", isLoading: true) {
            print("action")
        }
    }
}
