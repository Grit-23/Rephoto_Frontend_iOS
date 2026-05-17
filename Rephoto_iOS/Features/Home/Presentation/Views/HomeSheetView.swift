//
//  HomeSheetView.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI

struct HomeSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("설정") {
                    // SettingsView()
                    Text("설정")
                }
            }
            .navigationTitle("내 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
