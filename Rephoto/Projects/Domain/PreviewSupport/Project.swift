import ProjectDescription
import DependencyPlugin

/// 서버 없이 화면을 띄우기 위한 Repository 메모리 구현과 샘플 사진.
/// Feature Example 앱과 App의 DEBUG 조립에서만 링크한다. 검증은 Example 앱에서 하므로 Tests를 두지 않는다.
let project = Project.domain(
    .PreviewSupport,
    hasInterface: false,
    hasTesting: false,
    hasTests: false,
    implementationDependencies: [
        .domain(interface: .Photo),
        .domain(interface: .Tag),
        .shared(.Foundation),
    ],
    resources: ["Resources/**"]
)
