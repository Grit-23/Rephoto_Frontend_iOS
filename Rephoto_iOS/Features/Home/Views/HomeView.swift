//
//  HomeView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/8/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var sheetDetent: PresentationDetent = .medium
    
    @Bindable var vm : HomeViewModel
    
    init() {
        self.vm = .init()
    }
    
    
    var body: some View {
        VStack{
            topbar
            ScrollView{
                if vm.isWarning {
                    warningPhoto
                }
                PhotoCell
            }
            .sheet(isPresented: $vm.showSheet, content: {
                HomeSheetView(sheetDetent: $sheetDetent)
                    .presentationDetents([.medium, .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
            })
        }
        .padding(.horizontal)
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
                Image(systemName: "circle")
                    .resizable()
                    .frame(maxWidth: 40, maxHeight: 40)
            }
        }
        .tint(.black)
    }
    
    var warningPhoto: some View {
        NavigationLink{
            
        } label: {
            ZStack{
                Rectangle()
                .foregroundColor(.clear)
                .frame(width: 320, height: 136)
                .background(Color(red: 1, green: 0.99, blue: 0.99))

                .cornerRadius(20)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                .overlay(
                RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.89, green: 0.89, blue: 0.89), lineWidth: 1)

                )
                HStack(alignment: .top, spacing: 160){
                    VStack(alignment: .leading, spacing: 16){
                        Image(.warning)
                        Text("민감한 사진")
                            .font(.title2)
                            .bold(true)
                    }
                    
                    Text("54")
                        .bold()
                }
                .padding(.horizontal)
            }
            .tint(.black)
        }
        .padding(.top)
    }
    
    var PhotoCell : some View {
        VStack{
            
        }
    }
}


#Preview {
    HomeView()
}
