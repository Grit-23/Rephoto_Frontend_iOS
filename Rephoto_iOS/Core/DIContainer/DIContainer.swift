//
//  DIContainer.swift
//  Rephoto_iOS
//
//  Created by 김도연 on 3/4/26.
//

import Foundation
import SwiftData

@Observable
final class DIContainer {
    
    // MARK: - Storage
    @ObservationIgnored
    private var factories: [ObjectIdentifier: Any] = [:]
    @ObservationIgnored
    private var cachedInstances: [ObjectIdentifier: Any] = [:]
    
    // MARK: - Registration
    
    /// 프로토콜 타입과 팩토리 클로저를 등록
    ///
    /// - Parameters:
    ///   - type: 등록한 프로토콜 타입
    ///   - factory: 인스턴스를 생성하는 클로저
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }
    
    // MARK: - Resolution
    
    /// 등록된 의존성 조회
    ///  
    /// 최초 호출 시 팩토리 클로저로 인스턴스를 생성하고 캐시
    /// 이후 호출에선 캐시된 인스턴스 반환 (싱글톤 동작)
    ///  
    /// - Parameter type: 조회할 프로토콜/타입
    /// - Returns: 등록된 타입의 인스턴스
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let cached = cachedInstances[key] as? T {
            return cached
        }
        guard let factory = factories[key] as? () -> T else {
            fatalError("DIContainer Error: No Factory registered for type '\(T.self)'.")
        }
        let instance = factory()
        cachedInstances[key] = instance
        return instance
    }
    
    /// 등록 여부를 확인하며 의존성 조회
    ///
    /// - Returns: 등록된 경우 인스턴스, 미등록 시 nil
    func resolveIfRegistered<T>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)
        if let cached = cachedInstances[key] as? T {
            return cached
        }
        guard let factory = factories[key] as? () -> T else {
            return nil
        }
        let instance = factory()
        cachedInstances[key] = instance
        return instance
    }
    
    // MARK: - Cache Management

    /// 모든 캐시된 인스턴스를 초기화합니다.
    ///
    /// - Note: 로그아웃 시 호출하여 이전 사용자 상태를 제거합니다.
    func resetCache() {
        cachedInstances.removeAll()
    }
    
    /// 특정 타입의 캐시된 인스턴스만 초기화합니다.
    ///
    /// - Parameter type: 캐시를 제거할 타입
    func resetCache<T>(for type: T.Type) {
        let key = ObjectIdentifier(type)
        cachedInstances.removeValue(forKey: key)
    }
}

// MARK: - 앱 의존성 구성
extension DIContainer {
    
    static func configured(modelContext: ModelContext) -> DIContainer {
        let container = DIContainer()
        container.register(PathStore.self) { PathStore() }
        container.register(NavigationRouter.self) { NavigationRouter() }
        
        
        
        return container
    }
}
