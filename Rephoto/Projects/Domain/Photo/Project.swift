import ProjectDescription
import DependencyPlugin

// 의존성은 실제로 import할 때 추가한다 (예: interfaceDependencies: [.shared(.Foundation)]).
// 선언만 하고 import하지 않으면 tuist inspect dependencies가 실패한다.
let project = Project.domain(.Photo)
