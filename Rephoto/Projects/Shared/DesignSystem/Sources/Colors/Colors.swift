//
//  Colors.swift
//  DesignSystem
//
//  Created by Doyeon Kim on 11/2/26.
//

import SwiftUI

/// `Resources/Colors.xcassets`의 색을 다른 모듈에서 `.mainGreen`처럼 쓰기 위한 공개 접근자.
///
/// 별도 리소스 번들(`Bundle.module`)을 사용하면서 기존 화면의 `.mainGreen` 문법을 유지한다.
/// `baseColor` 에셋의 접근자 이름은 기존 Xcode 생성 심벌과 같은 `.base`다.
extension ShapeStyle where Self == Color {
    public static var base: Color { Color("baseColor", bundle: .module) }
    public static var deepGreen: Color { Color("deepGreen", bundle: .module) }
    public static var lightGreen: Color { Color("lightGreen", bundle: .module) }
    public static var mainGreen: Color { Color("mainGreen", bundle: .module) }
    public static var subGreen: Color { Color("subGreen", bundle: .module) }
    public static var labelPrimary: Color { Color("labelPrimary", bundle: .module) }
    public static var labelSecondary: Color { Color("labelSecondary", bundle: .module) }
    public static var labelTertiary: Color { Color("labelTertiary", bundle: .module) }
}
