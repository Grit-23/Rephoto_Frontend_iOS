//
//  HomeView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import Nuke
import NukeUI

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sheetDetent: PresentationDetent = .medium
    @Bindable var vm : HomeViewModel
    
    init() {
        self.vm = .init()
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                topbar
                PhotoCell
            }
            .sheet(isPresented: $vm.showSheet, content: {
                HomeSheetView(sheetDetent: $sheetDetent)
                    .presentationDetents([.medium, .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
            })
            .padding(.horizontal, 8)
        }
    }
    
    var topbar: some View {
        HStack{
            Text("앨범")
                .font(.largeTitle)
                .bold(true)
            
            Spacer()
            
            Button(action: {
                vm.showSheet.toggle()
            }) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(maxWidth: 40, maxHeight: 40)
            }
        }
        .tint(.black)
        .padding(.horizontal, 8)
    }
    
    var warningPhoto: some View {
        NavigationLink{
            
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, idealHeight: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
                
                HStack(spacing: 20){
                    Image(.warning)
                    Text("민감한 사진")
                        .font(.title2)
                        .bold(true)
                    Spacer()
                    Text("54")
                        .bold()
                }
                .padding(.horizontal)
            }
            .tint(.black)
            .padding(.horizontal, 1)
        }
    }
    
    var PhotoCell : some View {
        VStack {
            GeometryReader { geometry in
                ScrollView{
                    if vm.isWarning {
                        warningPhoto
                    }
                    
                    let side = (geometry.size.width - 8) / 3
                    let item = GridItem(.fixed(side), spacing: 4)
                    
                    LazyVGrid(columns: Array(repeating: item, count: 3), spacing: 4) {
                        ForEach(0..<demoPhotosURLs.count, id: \.self) { index in
                            LazyImage(url: demoPhotosURLs[index]) { state in
                                if let image = state.image {
                                    NavigationLink{
                                        PhotoInfoView(image: image)
                                    } label: {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: side, height: side)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
    HomeView()
}
