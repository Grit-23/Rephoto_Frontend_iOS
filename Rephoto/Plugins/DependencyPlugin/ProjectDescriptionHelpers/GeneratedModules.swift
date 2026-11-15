//
//  GeneratedModules.swift
//  DependencyPlugin
//
//  Scripts/generate-modules가 만든다. 직접 고치지 않는다.
//

public enum FeatureModule: CaseIterable {
    case Home
    case Search
    case User
}

public enum DomainModule: CaseIterable {
    case Album
    case Photo
    case PreviewSupport
    case Tag
    case User
}

public enum CoreModule: CaseIterable {
    case NetworkAdapter
}

public enum SharedModule: CaseIterable {
    case DesignSystem
    case Foundation
}
