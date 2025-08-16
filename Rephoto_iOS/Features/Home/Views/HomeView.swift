//
//  HomeView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI
import NukeUI
import PhotosUI

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var vm = HomeViewModel()
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showSheet: Bool = false
    
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack{
            VStack{
                if vm.images.isEmpty {
                    Spacer()
                    Text("등록된 사진이 없습니다.")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .bold()
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    photoCell
                }
            }
            .navigationTitle("앨범")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.showSheet.toggle()
                    }) {
                        Image(systemName: "person.fill")
                    }
                }
            }
            .tint(.black)
            .sheet(isPresented: $showSheet, content: {
                HomeSheetView(sheetDetent: $sheetDetent)
                    .presentationDetents([.medium, .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
            })
        }
    }
    
    var photoCell : some View {
        GeometryReader { geometry in
            let side = (geometry.size.width - 24) / 3
            let item = GridItem(.fixed(side), spacing: 4)
            
            ScrollView{
                VStack {
                    warningPhoto
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                    LazyVGrid(columns: Array(repeating: item, count: 3), spacing: 4) {
                        ForEach(vm.images) { photo in
                            LazyImage(url: photo.imageUrl) { state in
                                if let image = state.image {
                                    NavigationLink{
                                        PhotoInfoView(photo: photo)
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
            }
        }
    }
    
    var warningPhoto: some View {
        NavigationLink{
            
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(.clear)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
                HStack(spacing: 20){
                    Image("warning")
                    Text("민감한 사진")
                        .font(.title2)
                        .bold(true)
                    Spacer()
                    Text("\(vm.isWarningsCount)")
                        .bold()
                }
                .padding(.horizontal)
            }
            .tint(.black)
            .padding(.horizontal, 1)
        }
    }
}

#Preview {
    HomeView()
}
