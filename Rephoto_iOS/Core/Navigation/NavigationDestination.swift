//
//  NavigationDestination.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import Foundation

enum NavigationDestination: Hashable {
    
    /// 인증 관련 목적지
    enum Auth: Hashable {
        case test
    }
    
    enum Home: Hashable {
        /// 홈화면
        case photos
        /// 홈에서 선택한 사진 상세
        case detailPhoto/*(photo: PhotoResponseDto)*/
    }
    
    enum Map: Hashable {
        case map
    }
    
    enum Search: Hashable {
        case search
        
        case result(query: String)
    }
    
    case auth(Auth)
    case home(Home)
    case map(Map)
    case search(Search)
}
