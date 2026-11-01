# Rephoto iOS

AI 코딩 에이전트용 프로젝트 지침. `CLAUDE.md`는 이 파일을 import한다 — 이 파일만 고친다.

## Project Overview

사진 위치 기반 관리 앱. SwiftUI + Clean Architecture + MVVM. iPhone 전용, iOS 26.0+.

**빌드 축이 두 개다.** Tuist 전환(마일스톤 "Tuist 멀티모듈 전환")이 끝날 때까지 함께 유지한다.

| 축 | 위치 | 용도 |
| --- | --- | --- |
| 현행 앱 | `Rephoto_iOS.xcodeproj` | 출시 중인 코드. 버그 수정만. CI `iOS.yml` |
| Tuist 워크스페이스 | `Rephoto/` | 모든 신규·이관 작업. CI `tuist.yml` |

- SwiftUI. Tuist 워크스페이스는 **전 모듈 Swift 6 언어 모드**(`rephotoBaseSettings`), 예외 없음. 기존 `Rephoto_iOS.xcodeproj`는 Swift 5 유지
- 네트워크: 자체 레이어. `APITargetType`(엔드포인트) → `NetworkAdapter`(URLRequest 조립) → `NetworkClient`(actor, URLSession 실행·Bearer 주입·401 갱신)
- DI: Factory (`AppContainer`, `@Injected`). DEBUG에서 Mock provider 자동 주입
- 이미지: Nuke. 패키지: SPM (`Rephoto/Tuist/Package.swift`, Factory 2.5.3 · Nuke 12.8.0 exact)
- 도구 버전: `Rephoto/mise.toml` (tuist 4.155.0 · mockolo 2.7.0)

## Commands

Tuist 쪽 진입점은 `Rephoto/Makefile`이다. 모든 tuist 호출은 `mise exec`를 거친다.

```bash
cd Rephoto
make install                          # mise 도구 + SPM 의존성 (처음 한 번, 패키지 변경 시)
make generate                         # Mock 생성 → 워크스페이스 생성
make open                             # Rephoto.xcworkspace 열기
make build                            # generic 시뮬레이터 빌드 (SCHEME= 지정 가능)
make test                             # 테스트 (SCHEME= TEST_DESTINATION= 지정 가능)
make module type=feature name=Foo     # 모듈 스캐폴딩 + enum 재생성
make modules                          # GeneratedModules.swift만 재생성
make clean                            # 생성물 삭제 후 처음부터
```

`make generate`를 다시 돌려야 하는 경우: Project.swift · 플러그인 · xcconfig 수정, 모듈 추가, Finder로 파일 생성, Interface의 `/// @mockable` 변경, `Tuist/Package.swift` 변경, 매니페스트가 바뀐 브랜치로 체크아웃.

**Done criteria**: `tuist.yml`과 `iOS.yml` 둘 다 통과. Feature 모듈 변경은 해당 `<Name>FeatureExample` 앱으로 동작 확인. 성능에 닿는 변경은 `Rephoto_Performance` 플랜으로 메인 스레드 확인.

## Architecture

```
View → ViewModel → UseCase(Protocol) → Repository(Protocol) ← Repository(구현) → NetworkAdapter
```

### 계층과 타깃 (Tuist)

| 계층 | 모듈 | 기본 격리 | 역할 |
| --- | --- | --- | --- |
| Shared | Foundation(`RephotoFoundation`) | nonisolated | Config · Error 타입 · Loadable · 공용 확장 |
| Core | NetworkAdapter, UIComponents 등 | nonisolated | Feature · Domain이 공유하는 인프라 |
| Domain | Photo, Tag, Album, User, PreviewSupport | nonisolated | 업무 단위. 모델 · UseCase · Repository |
| Feature | Home, Search, User | MainActor | 화면 · ViewModel · UseCaseProvider |
| App | `Projects/App` | MainActor | 유일한 조립 지점. `AppContainer`가 구현을 등록 |

모듈 하나 = Tuist 프로젝트 하나 = `Projects/<계층>/<이름>/`. 타깃은 필요한 것만 둔다.

| 타깃 | 폴더 | 내용 |
| --- | --- | --- |
| Interface | `Interface/` | 다른 모듈에 공개하는 프로토콜과 모델. 구현 없음 |
| 구현 | `Sources/` | Interface 구현. Domain은 UseCase · Repository 구현 · DTO · API Target |
| Testing | `Testing/` | Interface의 테스트 더블. mockolo가 `Generated/Mocks.swift` 생성 |
| Tests | `Tests/` | 이 모듈의 단위 테스트 |
| Example | `Example/` | Feature만 단독 실행하는 앱. 나머지는 PreviewSupport Mock |

### 의존 규칙

- Feature → Domain Interface · Core · Shared. **구현 모듈(`XxxFeature`, `XxxDomain`) import 금지** — `tuist.yml`이 grep으로 차단
- Feature 간 참조는 상대 Feature의 Interface만 (예: Search가 Home의 사진 상세를 열 때 `HomeFeatureInterface`의 팩토리 프로토콜). Interface는 실제로 참조되는 Feature에만 둔다 — `Project.feature`의 `hasInterface` 기본값이 `false`인 이유
- 구현체 주입은 App의 `AppContainer`에서만. Feature는 `Container` extension에 프로토콜 Factory와 Preview 기본값만 선언한다
- 매니페스트는 문자열 대신 `DependencyPlugin` 헬퍼로 쓴다: `.domain(interface: .Photo)`, `.feature(interface: .Home)`, `.shared(.Foundation)`

### 격리와 동시성

- Feature · App은 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. ViewModel · View에 `@MainActor`를 명시하지 않는다
- Domain · Core · Shared는 `nonisolated`. UI 타입을 두지 않는다
- 전 모듈 `SWIFT_APPROACHABLE_CONCURRENCY = YES` → nonisolated async 함수는 호출자 액터에서 돈다. **디코딩 · 다운샘플 같은 CPU 작업은 `@concurrent`**
- 빌드 설정은 `Rephoto/Plugins/DependencyPlugin/ProjectDescriptionHelpers/Settings+Recommended.swift`와 각 Project.swift에서만 바꾼다. Xcode UI 변경은 generate 때 사라진다

### 핵심 플로우

- **인증**: `KeychainTokenStore`(actor) → `NetworkClient`가 Bearer 주입. 401이면 `TokenRefreshService`로 갱신 후 재시도(동시 갱신은 단일 Task). 갱신 실패 시 `SessionStore.forceLogout()`
- **업로드**: `PhotosPicker` → `HomeViewModel.handlePickedPhotos`가 `TaskGroup`으로 장별 병렬 → EXIF/GPS 추출 → 다운샘플 + JPEG 압축(ImageIO) → S3 업로드 → 메타데이터 일괄 저장
- **DTO → 도메인 모델** 매핑은 Repository에서. Presentation은 도메인 모델만 본다

### 절차

**모듈 추가**: `make module type=<feature|domain|core|shared> name=<PascalCase>` → 안 쓰는 폴더 삭제 → Project.swift의 `has*` 값 맞춤 → `make generate`.

**새 API**: Domain `Interface/`에 Repository 프로토콜 → `Sources/`에 API Target · DTO · Repository 구현 → UseCase 프로토콜(Interface)과 구현(Sources) → App `AppContainer`에 등록.

**기존 코드를 모듈로 옮길 때**: 경계 넘는 선언 `public` → `import` 추가(Interface만) → Swift 6 에러를 그 자리에서 고침(전역 가변 상태 · Sendable) → CPU 작업 `@concurrent` → Feature면 명시 `@MainActor` 제거 → Example 앱 확인.

## Code Style

- 4-space 들여쓰기. 타입 PascalCase, 프로퍼티·메서드 camelCase
- 새 파일 헤더 `Created by`는 현재 git user 이름
- `@Observable`로 통일. Combine 대신 async/await
- 모듈 밖에서 쓰는 타입 · 프로퍼티 · 이니셜라이저는 `public`. 그 외는 internal 유지
- 문서 · PR의 숫자 범위는 en dash(–), `~` 금지(GitHub가 취소선으로 렌더링)

## Testing

- Swift Testing 기본(`@Test("한글 설명")`). 성능 측정만 XCTest
- 테스트 플랜 2개: `Rephoto_iOS`(단위 · 계약, CI 게이트) / `Rephoto_Performance`(측정 전용, 수동)
- 네트워크 스텁은 `StubURLProtocol`. 스위트는 직렬화
- Tuist Testing 타깃의 Mock은 Interface 프로토콜에 `/// @mockable`을 붙이면 `make generate`가 만든다
- 가이드: `Rephoto_iOSTests/TEST_GUIDE.md`, 프레임워크 선택 기준 `Rephoto_iOSTests/TESTING.md`

## Git & PR

- 커밋: `<type>: <설명>` (`feat` `fix` `refactor` `test` `docs` `chore`). 괄호 scope 없이
- PR 제목: `[Feat]` `[Fix]` `[Refactor]` `[Docs]` `[Chore]` 대괄호 태그 + 설명
- 이슈 · PR은 `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md` 형식을 그대로 채운다
- **커밋 · PR에 AI 작성 흔적을 남기지 않는다.** `Co-Authored-By` 트레일러, "Generated with" 푸터 금지

## Gotchas

- 레포가 iCloud 경로다. DerivedData를 레포 안에 두면 resource fork 때문에 CodeSign이 실패한다. 기본 DerivedData 위치를 쓴다
- `*.xcodeproj` · `*.xcworkspace` · `Derived/` · `Testing/Generated/`는 생성물이라 gitignore. 클론 직후는 `make install && make generate`
- Interface가 없는 모듈(Core 기본)은 Testing이 구현을 `@testable import`로 본다
- `Config/Shared.xcconfig`는 커밋, `Config/Secrets.xcconfig`는 로컬 전용. 없어도 `#include?`라 빌드된다
- 레거시 기능(카메라 촬영, 지도 탭, 휴지통, 도움말, 카카오 OAuth)은 `../Rephoto_legacy`에만 있다. 부활시키지 않는다

## 참고 문서

| 문서 | 언제 읽나 |
| --- | --- |
| `docs/REFACTORING_HISTORY.md` | Step 1–7 리팩토링 이력과 결정 근거. 왜 지금 구조가 됐는지 볼 때 |
| `docs/benchmarks/` | 성능 · 빌드 시간 실측 원문 |
| `Rephoto_iOSTests/BASELINE_RESULTS.md` | 성능 수치 정리본 |
| `README.md` | 사용자용 소개 |
