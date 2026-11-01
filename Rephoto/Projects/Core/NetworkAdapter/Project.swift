import ProjectDescription
import DependencyPlugin

/// 네트워크 계층. 엔드포인트 선언(`APITargetType`) → 요청 조립(`NetworkAdapter`) →
/// 실행 · Bearer 주입 · 401 갱신(`NetworkClient`)까지와 토큰 저장소(`KeychainTokenStore`)를 둔다.
///
/// Testing은 `StubURLProtocol`과 손으로 만든 토큰 더블을 담는다 — Domain 모듈의 Repository 테스트가 가져다 쓴다.
let project = Project.core(
    .NetworkAdapter,
    hasTestHost: true,
    implementationDependencies: [
        .shared(.Foundation),
    ],
    testsDependencies: [
        .shared(.Foundation),
    ]
)
