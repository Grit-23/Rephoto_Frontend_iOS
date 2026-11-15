import ProjectDescription
import DependencyPlugin

// Interface는 다른 Feature가 이 Feature의 화면을 열어야 할 때만 둔다.
// 필요해지면 Interface/ 폴더를 만들고 hasInterface: true로 바꾼다.
let project = Project.feature(
    .User,
    hasInterface: false,
    hasTests: true,
    hasExample: true,
    implementationDependencies: [],
    // Example 앱에 주입할 Mock (예: .domain(implementation: .PreviewSupport))
    exampleDependencies: []
)
