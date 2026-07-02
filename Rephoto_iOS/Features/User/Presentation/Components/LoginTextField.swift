//
//  LoginTextField.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/2/26.
//

import SwiftUI

struct LoginTextField: View {
    let title: String
    let image: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.mainGreen)
            
            HStack(spacing: 12) {
                Image(systemName: image)
                    .foregroundStyle(.mainGreen)
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
            .padding()
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
            .font(.system(size: 16))
        }
    }
}
