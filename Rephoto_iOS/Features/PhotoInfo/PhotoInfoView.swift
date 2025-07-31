//
//  PhotoInfoView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/14/25.
//

import SwiftUI

struct PhotoInfoView : View {
    let image : Image
    
    
    var body: some View {
        VStack(spacing: 40){
            image
                .clipShape(RoundedRectangle(cornerRadius: 8))
            buttons
        }
    }
    
    
    var buttons : some View {
        HStack(spacing: 20){
            Button {
                
            } label: {
                Text("태그 수정")
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.color6)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
            }
            Button {
                
            } label: {
                Text("사진 공유")
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.color6)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
            }
        }
    }
}

#Preview {
    PhotoInfoView(image: Image("home"))
}
