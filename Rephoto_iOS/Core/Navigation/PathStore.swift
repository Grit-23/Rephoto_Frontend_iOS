//
//  PathStore.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import Foundation

@Observable
final class PathStore {
    
    // MARK: - Properties
    
    var homePath: [NavigationDestination] = []
    
    var mapPath: [NavigationDestination] = []
    
    var searchPath: [NavigationDestination] = []
    
    var mypagePath: [NavigationDestination] = []
    
    private var isUpdatingNoticePath: Bool = false
    
}
