//
//  NavigationRoutable.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import Foundation
import Combine

protocol NavigationRoutable {
    var destination: [NavigationDestination] { get set }
    func push(to view: NavigationDestination)
    func pop()
    func popToRootView()
}

@Observable
class NavigationRouter: NavigationRoutable {
    private var tabDestinations: [AnyHashable: [NavigationDestination]] = [:]
    private var currentTabKey: AnyHashable = "default"

    var destination: [NavigationDestination] {
        get { tabDestinations[currentTabKey] ?? [] }
        set { tabDestinations[currentTabKey] = newValue }
    }

    /// 현재 활성화된 탭 설정 (중복 호출 방지)
    func setCurrentTab<T: Hashable>(_ tab: T) {
        let newKey = AnyHashable(tab)
        guard currentTabKey != newKey else { return }
        currentTabKey = newKey
    }

    func push(to view: NavigationDestination) {
        destination.append(view)
    }

    func pop() {
        _ = destination.popLast()
    }

    func popToRootView() {
        destination.removeAll()
    }
}
