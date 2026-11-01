# 리팩토링 계획과 이력

아키텍처 · Concurrency · 모듈화 · 테스트 · CI/CD 순으로 진행하는 리팩토링 로드맵. 에이전트 작업 지침은 [AGENTS.md](../AGENTS.md)에 있고, 이 문서는 단계별 배경 · 결정 · 진행 상태를 기록한다.

> **진행 현황 (2026-11-01 기준)**: 안정화 수정 2건 머지 — 로그아웃 토큰 잔존·진행률 스레드(#76 → PR #77), 토큰 재발급 구조체 중복·로그아웃-갱신 경합(#78 → PR #79). 이후 Step 4(Tuist)를 마일스톤 "Tuist 멀티모듈 전환"으로 착수.
> - Step 1–3 **완료** (#14·#21·#23·#27·#44 / #29·#32 / #31)
> - Step 4 (Tuist 멀티모듈) — **진행 중**. PR 0(#90 → #91) 빌드 기준값 기록, PR 1(#92) Tuist 설정 + DependencyPlugin + Shared/Foundation 분리. 나머지 모듈 이관은 PR 2부터
> - Step 5 **부분 완료**: 단위·계약 테스트 95케이스(Swift Testing 83 + XCTest 12), 성능 플랜 18개(측정 전용). 미완: UseCase 전수 테스트, UI Test
> - Step 6 **부분 완료**: PR마다 빌드 + 유닛 플랜 실행 + `xccov` 커버리지 요약(#56). 미완: SwiftLint 워크플로, Fastlane TestFlight
> - Step 7 **부분 완료**: DateFormatter static 캐싱, 이미지 다운샘플·압축(#34·#49), Home 관찰 성능(#47·#59), 검색 디바운스(#53). 미완: ETag 캐시, Dictionary O(1) 태그 조회
>
> 남은 작업: Step 4 완료 후 README · 벤치마크 문서 갱신.

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
**현재**: `Rephoto/` 폴더에 Tuist 워크스페이스. 기존 `Rephoto_iOS.xcodeproj`는 전환이 끝날 때까지 병행 유지. PR 1에서 `Shared/Foundation`(Config · Error 타입 · Date 확장)과 임시 App 타깃까지 분리.
**목표**:
- **계층 4개**: Shared(Foundation) · Core(NetworkAdapter, UIComponents 등 공유 인프라) · Domain(Photo, Tag, Album, User 등 업무 단위 + PreviewSupport) · Feature(Home, Search, User). 기존 Feature 폴더의 Domain/Data는 Domain 모듈로, Presentation만 Feature 모듈로 간다
- **모듈 = Tuist 프로젝트 1개**, 타깃은 `Interface · Sources · Testing · Tests`(Feature는 `Example` 추가) 중 필요한 것만. Interface는 프로토콜·모델만, Sources가 구현, Testing은 mockolo가 만든 Mock, Example은 Feature 단독 실행 앱
- **의존 규칙**: Feature → Domain Interface · Core · Shared. Feature 간, Feature → Domain은 **Interface 타깃만 허용**, 구현 모듈 import는 CI가 차단(`tuist.yml`). 구현 조립은 App 타깃의 `AppContainer` 한 곳
- **DependencyPlugin**: 폴더 이름 → 모듈 enum(`GeneratedModules.swift`) 자동 생성, `.feature(interface: .Home)` 같은 타입 안전 의존성 헬퍼, `Project.feature(...)` 한 줄로 타깃 일괄 생성. 모듈 추가는 `make module type= name=`
- 모든 Feature는 Example 앱으로 동작 확인 후 PR. iPhone 전용
- 새 워크스페이스는 전 모듈 Swift 6 언어 모드(PR 1부터, 예외 없음). 옮기면서 생기는 Swift 6 에러는 그 모듈에서 바로 고친다. 기존 xcodeproj는 Swift 5 유지
- **PR 2 (Core · Foundation 정리)**: 에러 타입 간소화 — `DomainError.custom` 삭제, `RepositoryError` 두 케이스를 `invalidData(detail:)` 하나로, `PresentableError`의 중복 `retryAction` 필드 삭제, 세 계층 enum이 공통 프로토콜을 채택해 `AppError`의 반복 switch 제거. `AppError.from` 매핑 · `Loadable` 전이를 Foundation Tests로 검증
- **PR 4 (Home 이관)**: `HomeViewModel`의 `photos` · `isLoading` · `loadError`를 `Loadable<[Photo]>` 하나로. `visiblePhotos` · `sensitivePhotos` 파생 캐싱은 `didSet`으로 유지하고, 사진이 이미 있을 때는 `.loading`으로 바꾸지 않고 실패만 Alert로 알리는 기존 동작을 지킨다. API · Repository · UseCase는 변경 없음
- 보류: 민감 사진을 Home에서 내려받지 않고 Face ID 통과 후 별도 요청으로 받는 설계. 프라이버시 이점은 있으나 엔드포인트 · Search 매핑까지 갈라야 해 전환 범위 밖

빌드 시간 기준값: `docs/benchmarks/2026-10-29_build_time.md`.

## Step 5. 🔶 테스트 커버리지 강화 (부분 완료)

**리팩토링 전**: 성능 벤치마크만 존재. UseCase/ViewModel 단위 테스트 없음. UI 테스트 없음.
**현재**: 단위·계약 95케이스(네트워크 코어 41 · 엔드포인트 명세 35 · 응답 DTO 6 · 업로드 전처리 1 · Presentation 12) + 성능 플랜 18개. UseCase 전수 테스트와 UI Test는 미완.
**목표**:
- Domain UseCase 단위 테스트: mock repository 주입하여 비즈니스 로직 검증
- ViewModel 상태 테스트: UseCase mock 주입 → 입력 이벤트 → 상태 변화 assertion
- Network 레이어 stub 테스트: `StubURLProtocol`로 응답 시나리오 검증 (Moya stubClosure 대체)
- UI Test: 로그인 → 사진 목록 → 업로드 핵심 플로우 자동화
- 모듈별 독립 테스트 타겟 (Step 4 Tuist 구조 활용)

## Step 6. 🔶 CI/CD (GitHub Actions + Fastlane) (부분 완료)

**리팩토링 전**: 수동 빌드/배포. 코드 스타일 규칙 미적용.
**현재**: `iOS.yml` 하나가 PR마다 `build-for-testing` → `test-without-building`(`-testPlan Rephoto_iOS`) → `xcrun xccov` 커버리지 요약까지 수행(#56). `tuist.yml`이 Tuist 워크스페이스를 generic 시뮬레이터로 빌드. SwiftLint 워크플로와 Fastlane은 미착수.
**목표**:
- GitHub Actions workflow: PR 생성 시 자동 빌드 + 전체 테스트 실행
- SwiftLint 자동 체크 (PR에 violation 코멘트)
- Fastlane lane: TestFlight beta 자동 배포
- 코드 커버리지 리포트 자동 생성 + PR에 첨부
- Tuist 기반 빌드이므로 `tuist generate` → `xcodebuild` 파이프라인

## Step 7. 🔶 성능 최적화 (부분 완료)

**리팩토링 전**: DateFormatter 매번 생성, 이미지 원본 업로드, fetchPhotos() 전체 교체, 태그 배열 선형 검색.
**현재**: DateFormatter static 캐싱 완료, 이미지 다운샘플·압축 완료(#34·#49 — 페이로드 중앙값 −73%, 다운샘플·인코딩 시간 중앙값 −25% — iPhone 14 Pro 1대 · 사진 15장), Home 파생 컬렉션 didSet 캐싱(#47·#59). ETag 캐시와 Dictionary O(1) 태그 조회는 미완(`PhotoInfoViewModel`이 아직 `firstIndex` 선형 검색).
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
