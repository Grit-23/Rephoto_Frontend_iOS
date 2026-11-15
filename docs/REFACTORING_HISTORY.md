# 리팩토링 계획과 이력

아키텍처 · Concurrency · 모듈화 · 테스트 · CI/CD 순으로 진행하는 리팩토링 로드맵. 에이전트 작업 지침은 [AGENTS.md](../AGENTS.md)에 있고, 이 문서는 단계별 배경 · 결정 · 진행 상태를 기록한다.

> **진행 현황**: Home · Search · User 이관과 최종 통합 검증(#108)까지 끝났다. 남은 것은 기존 프로젝트 제거다.
> - Step 1–3 **완료** (#14·#21·#23·#27·#44 / #29·#32 / #31)
> - Step 4 (Tuist 멀티모듈) — **진행 중**. PR 0(#91) 빌드 기준값, PR 1(#93) Tuist·DependencyPlugin·Foundation, PR 2(#95) NetworkAdapter·DesignSystem·에러 통합, PR 3(#98 · #99) Home, PR 4(#101 · #102) Search, PR 5(#104 · #106) User, 최종 통합 검증(#108) 완료. 남은 것은 기존 프로젝트 · `iOS.yml` 제거
> - Step 5 **부분 완료**: Tuist 워크스페이스에 단위·계약 테스트 200케이스(Swift Testing, 모듈 10개), 성능 벤치마크 18개(측정 전용, 앱 호스트 타깃). 미완: UseCase 전수 테스트, UI Test
> - Step 6 **부분 완료**: PR마다 빌드 + 유닛 플랜 실행 + `xccov` 커버리지 요약(#56, `tuist.yml`은 #108). 미완: SwiftLint 워크플로, Fastlane TestFlight
> - Step 7 **부분 완료**: DateFormatter static 캐싱, 이미지 다운샘플·압축(#34·#49), Home 관찰 성능(#47·#59), 검색 디바운스(#53). Tuist 전환 후 실기기 재측정에서 같은 값 확인(#108). 미완: ETag 캐시, Dictionary O(1) 태그 조회
>
> 남은 작업: 기존 프로젝트 제거.

## 제거된 기능

PhotoCapture(카메라 촬영), 지도 탭(Map 화면 — 사진 상세의 위치 지도는 유지), 휴지통, 도움말, 카카오 OAuth. 레거시에만 존재하며 리팩토링 전 코드는 형제 디렉토리 `../Rephoto_legacy`에 보존돼 있다. 문서나 README에서 언급을 발견해도 부활시키지 않는다.

## Step 1. ✅ Clean Architecture + DI 전환 (완료)

**리팩토링 전**: ViewModel 내부에서 MoyaProvider 직접 생성. 레이어 경계 없음. 테스트 시 stub 주입 불가.
**목표**:
- Feature별 Data/Domain/Presentation 3레이어 분리
- Domain 레이어에 UseCase 프로토콜 정의 → Implementations/ 에 구현체
- Repository 프로토콜 (Domain/Interfaces/) ← Repository 구현 (Data/) 분리
- DIContainer + UseCaseProvider 도입. ViewModel 생성자에서 UseCase 주입
- DTO → Domain Model 매핑을 Data 레이어에 격리 (Presentation은 Domain Model만 사용)

## Step 2. ✅ Token 관리 — Keychain + Actor (완료)

**리팩토링 전**: UserDefaults에 토큰 직접 저장. 보안 취약 + 매 읽기/쓰기마다 디스크 I/O. race condition 가능성.
**목표**:
- KeychainTokenStore를 Swift actor로 구현 → thread-safe 보장
- NetworkClient actor: 토큰 주입(AuthPlugin) + 401 감지 시 TokenRefreshService 호출 → 토큰 갱신 후 원래 요청 재시도
- AuthSystemFactory로 NetworkClient 조립 (TokenStore, RefreshService 의존성 주입)
- 토큰 만료/갱신/삭제 시나리오별 에러 처리 (로그아웃 유도 포함)

## Step 3. ✅ Swift Concurrency 전면 전환 (완료)

**리팩토링 전**: `Data(contentsOf:)` 동기 로딩 + for loop 순차 처리. completion handler 혼재. 메인 스레드 블로킹.
**목표**:
- async/await 전면 도입. completion handler 전량 제거
- TaskGroup으로 사진 병렬 로딩 (HomeViewModel.handlePickedPhotos())
- @MainActor 격리: ViewModel의 UI 상태 변경을 메인 스레드 보장
- Sendable 준수: actor 경계를 넘는 데이터 타입 점검
- Task cancellation 처리: 화면 이탈 시 진행 중 작업 취소
- 네트워크 레이어 async화: MoyaProvider → async wrapper

**이후 변경**: Moya는 PR #46에서 완전 제거(SPM 6개 → 2개). 엔드포인트 선언은 자체 `APITargetType`, 요청 조립은 `NetworkAdapter`, 실행·인증은 URLSession 기반 `NetworkClient`(actor).

**단일 타깃 시절의 격리 설정**: 앱 타깃은 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`를 명시해 `@Observable` 클래스가 자동으로 메인 액터 격리되지 않았고, ViewModel마다 `@MainActor`를 직접 붙였다. 단일 타깃에서 `MainActor`로 켜면 Data 레이어(Repository·DTO 매핑)까지 MainActor로 추론되어 디코딩이 메인에서 돌기 때문이다. `SWIFT_APPROACHABLE_CONCURRENCY`는 테스트 타깃에만 YES였다. Step 4에서 "UI 모듈 = MainActor / 비UI 모듈 = nonisolated"를 모듈 설정으로 일괄 적용하고 Approachable Concurrency를 전 모듈 YES로 통일하면서 이 불일치가 해소된다.

## Step 4. 🔶 Tuist + 멀티모듈 분리 (진행 중)

**리팩토링 전**: 단일 앱 타겟. .xcodeproj 직접 관리. Feature 간 암묵적 의존(Search가 Home의 `PhotoInfoView`를, Home이 User의 `SettingsView`를 직접 참조). `AppContainer`가 Core에 있으면서 모든 Feature 구현을 앎.
**착수 전 안정화**: 로그아웃 토큰 잔존·진행률 스레드(#76 → PR #77), 토큰 재발급 구조체 중복·로그아웃-갱신 경합(#78 → PR #79) 수정 후 마일스톤 "Tuist 멀티모듈 전환"으로 착수.
**현재**: `Rephoto/`에 Tuist 워크스페이스와 App 타깃, Shared/Foundation·DesignSystem, Core/NetworkAdapter, Domain/Photo·Tag·Album·User·PreviewSupport, Feature/Home·Search·User(Example · App 탭 조립 · 로그인 분기)까지 분리 완료(PR 0 #91 · PR 1 #93 · PR 2 #95 · PR 3-1 #98 · PR 3-2 #99 · PR 4-1 #101 · PR 4-2 #102 · PR 5-1 #104 · PR 5-2 #106), 최종 통합 검증(#108)으로 성능 벤치마크 · 문서 · 목 서버 경로까지 옮겼다. 기존 `Rephoto_iOS.xcodeproj`와 `iOS.yml`은 다음 이슈에서 삭제한다.
**목표**:
- **계층 4개**: Shared(Foundation · DesignSystem) · Core(NetworkAdapter 등 공유 인프라) · Domain(Photo, Tag, Album, User 등 업무 단위 + PreviewSupport) · Feature(Home, Search, User). 기존 Feature 폴더의 Domain/Data는 Domain 모듈로, Presentation만 Feature 모듈로 간다
- **모듈 = Tuist 프로젝트 1개**, 타깃은 `Interface · Sources · Testing · Tests`(Feature는 `Example` 추가) 중 필요한 것만. Interface는 프로토콜·모델만, Sources가 구현, Testing은 mockolo가 만든 Mock, Example은 Feature 단독 실행 앱
- **의존 규칙**: Feature → Domain Interface · Core · Shared. Feature 간, Feature → Domain은 **Interface 타깃만 허용**, 구현 모듈 import는 CI가 차단(`tuist.yml`). 구현 조립은 App 타깃의 `AppContainer` 한 곳
- **DependencyPlugin**: 폴더 이름 → 모듈 enum(`GeneratedModules.swift`) 자동 생성, `.feature(interface: .Home)` 같은 타입 안전 의존성 헬퍼, `Project.feature(...)` 한 줄로 타깃 일괄 생성. 모듈 추가는 `make module type= name=`
- 모든 Feature는 Example 앱으로 동작 확인 후 PR. iPhone 전용
- 새 워크스페이스는 전 모듈 Swift 6 언어 모드(PR 1부터, 예외 없음). 옮기면서 생기는 Swift 6 에러는 그 모듈에서 바로 고친다. 기존 xcodeproj는 Swift 5 유지
- **PR 2 완료 (Core 분리 · 에러 통합, #95)**: `NetworkAdapter`(Core)와 `DesignSystem`(Shared, MainActor) 분리, 첫 테스트 타깃과 `Rephoto.xctestplan`. 에러는 계층 enum(`NetworkError` · `RepositoryError` · `DomainError`)이 분류만 하고 사용자 문구 · 재시도 정책은 `AppError` 한 곳에서 결정, UI는 `ErrorHandler`(Alert) · `ErrorStateView`(인라인) 둘만 둔다 — `ErrorDisplay` · `ErrorContext` · `PresentableError` 타입 삭제, `GlobalErrorAlert`는 public 타입에서 `globalErrorAlert(_:)` 모디파이어의 private 구현으로, `DomainError.custom` 삭제, `RepositoryError`는 `invalidData(detail:)` 하나, `NetworkAdapter.request`는 `Data`만 반환(`NetworkResponse` 삭제), `Loadable`은 case만 남김(접근자는 쓰는 곳이 생길 때 추가). "공통 프로토콜" 안은 폐기
- **PR 2 인증 단순화**: Tuist의 `KeychainTokenStore`는 `TokenPair`를 단일 `tokens` 항목에 저장하는 동기 struct로 바꿔 두 키의 부분 저장·롤백을 없앤다. `NetworkClient` actor가 세션 세대 확인과 저장·삭제를 중단 없이 수행하므로, 전환 카운터와 이전 갱신 종료 대기도 제거한다. 동시 갱신은 단일 Task를 공유하고, 이전 세션의 인증 요청·갱신 결과는 취소로 끝낸다. 공개 경로(`/login` · `/join` · `/auth/refresh`)는 세대 검사와 401 갱신을 거치지 않는다.
- 보류: 민감 사진을 Home에서 내려받지 않고 Face ID 통과 후 별도 요청으로 받는 설계. 프라이버시 이점은 있으나 엔드포인트 · Search 매핑까지 갈라야 해 전환 범위 밖

### 남은 이관 순서

Domain 전체를 먼저 옮기는 단계는 두지 않는다. **Home → Search → User** 순서로 필요한 Domain·Feature·테스트·Example을 함께 완료한다. PreviewSupport와 Mock도 각 화면에서 필요한 것만 추가한다.

| 단계 | 이관 범위 | 완료 확인 |
| --- | --- | --- |
| PR 3-1 · Home Domain (#98) | Photo·Tag Domain, PreviewSupport(Repository 메모리 구현 + 샘플 사진). 사진 설명·메타데이터 추출·업로드는 PhotoDomain에 포함. Interface 프로토콜에 `Sendable`·`/// @mockable` 첫 적용 | Repository·UseCase 테스트, 디코딩이 메인 액터 밖에서 도는지 테스트로 확인 |
| PR 3-2 · Home Feature (#99) | HomeFeature·HomeFeatureExample, App 조립(`AppContainer`), AGENTS.md DI 규칙. `HomeView`는 Provider · `ErrorHandler` · 프로필 액션을 init으로 받고 Factory는 App만 import. `HomeViewModel` 상태는 `Loadable<[Photo]>` 하나. App이 Factory를 링크하면서 Xcode 27이 외부 패키지 리소스 번들(Factory PrivacyInfo)의 iOS 13 배포 타깃을 에러로 막아, `make generate`가 `Scripts/patch-package-deployment-target`로 생성물을 보정 | ViewModel 테스트, 목록·업로드·상세·태그·민감 사진·프로필 액션을 Home Example에서 확인 |
| PR 4-1 · Search Domain (#101) | AlbumDomain(앨범 목록 Repository, 앨범 목록·앨범 사진 UseCase), PhotoDomain의 검색 모델·Repository·UseCase와 태그별 사진 조회, PreviewSupport의 앨범·검색 메모리 구현. 앨범 사진 응답은 사진 형식이라 `PhotoRepositoryProtocol.getPhotos(tagId:)`가 맡고, `GetAlbumPhotosUseCase`가 PhotoDomainInterface로 호출한다 | Album·Search Repository·UseCase 테스트, 디코딩이 메인 액터 밖에서 도는지 테스트로 확인 |
| PR 4-2 · Search Feature (#102) | SearchFeature·SearchFeatureExample, HomeFeatureInterface의 사진 상세 팩토리(`PhotoDetailBuilding` — HomeFeature의 `PhotoDetailBuilder`가 `PhotoInfoView`로 구현, App이 조립), App 탭 조립. `SearchView`는 Provider · 사진 상세 팩토리 · 검색어를 init으로 받고 Factory는 import하지 않는다. 검색 필드가 탭 바에 합쳐지도록 `.searchable`은 `TabView`를 가진 쪽(App의 `RephotoTabView`, Example)이 붙인다. 탭 뷰(`RephotoTabView`)는 App 타깃에 두고 컨테이너는 루트에서만 읽어 init으로 넘긴다. 앨범 사진·색인은 Home과 같은 `PhotoRepository` 싱글턴. Example은 사진 상세를 Home 없이 대체 화면으로 띄운다. 상세에서 삭제한 사진이 반영되도록 `SearchView`의 앨범·색인 `.task`는 NavigationStack 안쪽에 둬 돌아올 때 다시 돌고(`AlbumViewModel`은 목록이 있으면 `.loading` 전환 없이 교체, 갱신 실패 시 유지), PreviewSupport의 앨범·검색 Repository는 고정 fixture 대신 공유 `PreviewPhotoRepository` 상태로 집계한다 | ViewModel 테스트(검색·빈 결과·실패·늦은 결과 무시·색인 폴백, 앨범 목록·앨범 사진·갱신 시 목록 유지), Search Example에서 검색·앨범·사진 상세 연결과 삭제 반영 확인 |
| PR 5-1 · User Domain (#104) | UserDomain(Repository · UseCase 3개 · API Target · DTO), PreviewSupport의 사용자 메모리 구현. `NetworkClient`는 UserDomain 구현만 쥐고 Interface로 드러내지 않는다. 호출하는 곳이 없는 `join` · `updateUser` · `deleteUser` 엔드포인트도 그대로 옮긴다 | User API Target 계약 · Repository(로그인 토큰 저장, 로그아웃 시 토큰 삭제) · UseCase 테스트, 디코딩이 메인 액터 밖에서 도는지 테스트로 확인 |
| PR 5-2 · User Feature (#106) | UserFeature·UserFeatureExample, 계정 시트(`AccountSheetView`, 기존 `HomeSheetView`), `SessionStore`·App 인증 연결. 설정 화면은 없애고 계정 시트 한 장(medium 고정)에 프로필 · 버전 · 로그아웃을 모았다. 글래스는 아바타 · 버전 아이콘 · 로그아웃 버튼에만 쓴다. `SessionStore`는 App이 하나 만들어 `LoginView`와 계정 시트에 init으로 넘기고 탭 뷰에 `environment`로 싣지 않는다. 다른 Feature가 User를 참조하지 않아 Interface 타깃은 없다. 갱신 실패 핸들러는 `setOnRefreshFailed`가 `async`라 `SessionStore.init`이 아니라 `restore()`에서 등록을 기다린 뒤 토큰을 확인한다. App 루트(`RootView`)가 `isLoggedIn`으로 로그인 화면과 탭을 가르고, 계정 시트 표시 상태는 탭 뷰(`RephotoTabView`)가 가져 로그아웃하면 함께 사라진다. `ErrorHandler.onSessionExpired`는 `forceLogout()`으로 연결. `.searchable`은 `TabView` 전체가 아니라 검색 탭 콘텐츠에 붙인다 — `TabView`에 붙이면 선택된 탭의 내비게이션 바에 필드가 놓여 홈에도 검색 필드가 뜬다. DEBUG는 기본으로 메모리 Repository(로그인된 상태로 시작)를 쓰고 실행 인자 `-useServer`를 주면 `Config.baseURL` 서버에 붙는다 | 세션 8 · 로그인 ViewModel 4 테스트(XCTest → Swift Testing, mockolo Mock), User Example와 App에서 로그인·복원·로그아웃·갱신 실패 확인 |
| 최종 통합 검증 (#108) | 성능 벤치마크 18개를 App 프로젝트의 `RephotoPerformanceTests`로 이관(실기기는 호스트 앱이 있는 테스트만 돌릴 수 있어 모듈 Tests가 아니라 앱에 붙였다), `Rephoto_Performance` 플랜 · `make perf`, 입력 사진 경로와 `.gitignore`, 앱 아이콘, `mock_server.py` 이미지 경로 · 연결 안내, `tuist.yml` 커버리지 요약, `docs/TESTING.md` · `docs/BASELINE_RESULTS.md`를 Tuist 기준으로 재작성, README · AGENTS.md 갱신 | 단위 테스트 200개 · 성능 벤치마크 18개 통과, iPhone 14 Pro 재측정에서 전환 전과 같은 값(업로드 파일 14장 바이트 단위 동일), 빌드 시간 증분 −38% · 클린 +10% |
| 기존 프로젝트 제거 (예정) | `Rephoto_iOS/` · `Rephoto_iOSTests/` · `Rephoto_iOS.xcodeproj` · 루트 테스트 플랜 2개 · `Rephoto-iOS-Info.plist` · `iOS.yml` 삭제 | `tuist.yml` 통과 후 마일스톤 종료 |

- **Home–User 경계**: Home은 프로필 버튼 액션을 주입받는다. App이 계정 시트 표시를 소유하고, 기존 `HomeSheetView`의 계정 UI·설정·세션 연결은 PR 5에서 User와 함께 옮긴다. PR 3 Example에서는 주입한 액션을 확인하며, User Interface나 공용 라우터를 선행 도입하지 않는다
- **Home 상태 보존(PR 3)**: `HomeViewModel`의 `photos` · `isLoading` · `loadError`를 `Loadable<[Photo]>` 하나로 바꾼다. `visiblePhotos` · `sensitivePhotos` 파생 캐싱은 `didSet`으로 유지한다. 사진이 이미 있을 때는 `.loading`으로 바꾸지 않고 실패만 Alert로 알리는 기존 동작을 지킨다. 이 상태 변경을 위해 API · Repository · UseCase 동작은 바꾸지 않는다
- **Search 경계**: `SearchResult`·`SearchRepository`·`SearchUseCase`는 PhotoDomain에 포함하고 별도 SearchDomain은 만들지 않는다. 앨범 사진 목록도 사진 응답 DTO를 공유하므로 PhotoDomain Repository가 조회하고, AlbumDomain은 앨범 목록만 디코딩한다. `GetPhotosUseCase`는 PhotoDomainInterface로, 사진 상세는 HomeFeatureInterface로 사용한다. DTO는 각 구현 모듈 안에 두고 Interface로 노출하지 않는다
- **작업 크기**: 기본은 Feature별 PR 하나다. Home은 파일 수가 많아 Domain(3-1) · Feature(3-2)로 나눴다. User는 Feature PR이 App 인증 연결을 담아 Domain(5-1)을 먼저 뗐다. 나눌 때는 Domain PR이 테스트만으로 검증 가능한 단위가 되도록 자르고, 처음부터 추가 계층이나 모듈을 만들지 않는다
- **PR 3-1에서 확인한 것**: `ISO8601DateFormatter`는 Swift 6에서 non-Sendable이라 `static let`에 둘 수 없다(`DateFormatter`는 가능). 값 타입 `Date(_:strategy: .iso8601)`로 대체한다. mockolo는 `Sendable` 프로토콜의 Mock을 `@unchecked Sendable` + `Mutex`로 생성한다. Tests 타깃이 Testing 타깃을 import하지 않으면 `tuist inspect dependencies`가 중복 의존으로 잡으므로, Mock을 쓰는 테스트가 모듈마다 하나는 있어야 한다
- **각 PR의 완료 기준**: 해당 Domain·Feature 테스트와 `<Name>FeatureExample` 동작 확인, `tuist.yml`·`iOS.yml` 모두 통과. 성능에 닿는 변경은 `Rephoto_Performance` 플랜으로 확인한다. 최종 통합 검증 전에 기존 빌드 축을 제거하지 않는다
- **범위**: 기존 사용자가 없는 개인 학습 프로젝트이므로 사용자 데이터·토큰 마이그레이션은 추가하지 않는다

빌드 시간: 전환 후 증분 −38%, 클린 +10% — `docs/benchmarks/2026-10-29_build_time.md`.

## Step 5. 🔶 테스트 커버리지 강화 (부분 완료)

**리팩토링 전**: 성능 벤치마크만 존재. UseCase/ViewModel 단위 테스트 없음. UI 테스트 없음.
**현재**: Tuist 워크스페이스에 단위·계약 200케이스(Core 43 · Shared 24 · Domain 83 · Feature 50) + 성능 벤치마크 18개. 기존 프로젝트의 95케이스는 제거 전까지 남는다. UseCase 전수 테스트와 UI Test는 미완. 구성은 `docs/TESTING.md`.
**목표**:
- Domain UseCase 단위 테스트: mock repository 주입하여 비즈니스 로직 검증
- ViewModel 상태 테스트: UseCase mock 주입 → 입력 이벤트 → 상태 변화 assertion
- Network 레이어 stub 테스트: `StubURLProtocol`로 응답 시나리오 검증 (Moya stubClosure 대체)
- UI Test: 로그인 → 사진 목록 → 업로드 핵심 플로우 자동화
- 모듈별 독립 테스트 타겟 (Step 4 Tuist 구조 활용)

## Step 6. 🔶 CI/CD (GitHub Actions + Fastlane) (부분 완료)

**리팩토링 전**: 수동 빌드/배포. 코드 스타일 규칙 미적용.
**현재**: `iOS.yml`이 PR마다 `build-for-testing` → `test-without-building`(`-testPlan Rephoto_iOS`) → `xcrun xccov` 커버리지 요약까지 수행(#56). `tuist.yml`은 `make build`로 generic 시뮬레이터 빌드 후 `make test`로 Tuist 테스트 플랜을 실행하고 커버리지 요약을 남긴다(#108). 두 CI는 기존 프로젝트 제거까지 유지한다. SwiftLint 워크플로와 Fastlane은 미착수.
**목표**:
- GitHub Actions workflow: PR 생성 시 자동 빌드 + 전체 테스트 실행
- SwiftLint 자동 체크 (PR에 violation 코멘트)
- Fastlane lane: TestFlight beta 자동 배포
- 코드 커버리지 리포트 자동 생성 + PR에 첨부
- Tuist 기반 빌드이므로 `tuist generate` → `xcodebuild` 파이프라인

## Step 7. 🔶 성능 최적화 (부분 완료)

**리팩토링 전**: DateFormatter 매번 생성, 이미지 원본 업로드, fetchPhotos() 전체 교체, 태그 배열 선형 검색.
**현재**: DateFormatter static 캐싱 완료, 이미지 다운샘플·압축 완료(#34·#49 — 페이로드 중앙값 −73%, 다운샘플·인코딩 시간 중앙값 −25% — iPhone 14 Pro 1대 · 사진 15장), Home 파생 컬렉션 didSet 캐싱(#47·#59). Tuist 전환 후 실기기 재측정(#108, 사진 14장)에서 페이로드 −72.7% · 시간 −24.6%로 같은 값이 나왔다. ETag 캐시와 Dictionary O(1) 태그 조회는 미완(`PhotoInfoViewModel`이 아직 `firstIndex` 선형 검색).
**목표**:
- DateFormatter static 캐싱 또는 ISO8601DateFormatter 전환
- 업로드 전 이미지 압축 (quality 0.7–0.8)
- ETag/Last-Modified 기반 캐시 → 변경분만 diff 업데이트
- Dictionary 기반 O(1) 태그 조회 + 낙관적 업데이트 실패 시 롤백

## 의존성 흐름

```
Step 1 (Clean Arch + DI)
  └→ Step 2 (Token/Actor)
      └→ Step 3 (Concurrency)
          └→ Step 4 (Tuist 모듈화)
              ├→ Step 5 (테스트)
              └→ Step 6 (CI/CD)
                  └→ Step 7 (성능 최적화)
```
