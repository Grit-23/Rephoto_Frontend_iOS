//
//  Rephoto_iOSApp.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 7/3/25.
//

import SwiftUI
import Factory

@main
struct Rephoto_iOSApp: App {
    @Injected(\.userUseCaseProvider) private var userProvider

    var body: some Scene {
        WindowGroup {
            ContentView(userProvider: userProvider)
        }
    }
}
