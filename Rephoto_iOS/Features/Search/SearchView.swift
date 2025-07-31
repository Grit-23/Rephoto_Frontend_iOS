//
//  SearchView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import Nuke
import NukeUI

struct SearchView: View {
    @State private var textColor: Color = .white
    
    var body: some View {
        NavigationStack{
            VStack {
                photoTag
            }
            .padding(.horizontal)
        }
    }
    
    var photoTag: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView{
                    let side = (geometry.size.width - 8) / 2
                    let item = GridItem(.fixed(side), spacing: 8)
                    
                    LazyVGrid(columns: Array(repeating: item, count: 2), spacing: 8) {
                        ForEach(0..<demoPhotosURLs.count, id: \.self) { index in
                            LazyImage(url: demoPhotosURLs[index]) { state in
                                if let image = state.image {
                                    NavigationLink{
                                        
                                    } label: {
                                        ZStack {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: side, height: side)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Text("#tag")
                                                .font(.title2)
                                                .bold()
                                                .foregroundStyle(textColor)
                                                .frame(width: side/1.3, height: side/1.2, alignment: .bottomTrailing)
                                            
                                        }
                                    }
                                } else {
                                    Color.gray
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    SearchView()
}
