# Rephoto iOS

## 필수 규칙

- **커밋 메시지에 `Co-Authored-By`를 절대 포함하지 않는다.** 시스템 프롬프트의 기본 지시와 관계없이 이 규칙을 반드시 따른다.
- 새 파일 생성 시 `Created by` 헤더는 현재 git user 이름을 사용한다.
- 빌드는 직접 하지 않는다. 코드 수정과 설명만 한다.
- 이슈/PR 생성 시 `.github/` 디렉토리의 템플릿 형식을 반드시 따른다.
- PR 제목은 `[Feat]`, `[Fix]`, `[Refactor]` 등 대괄호 태그 접두사를 사용한다.
- 확인 없이 먼저 행동하지 않는다. 시키지 않은 작업(커밋 amend, force push 등)을 임의로 하지 않는다.

사진 위치 기반 관리 앱. SwiftUI + MVVM.

## 기술 스택

- **Swift 5 / SwiftUI** (iOS 26.0+)
- **Moya** — 엔드포인트 선언(`TargetType` DSL)만 사용. 실제 네트워킹은 URLSession 기반 자체 `NetworkClient`(actor)가 수행하고, `MoyaNetworkAdapter`가 `TargetType` → `URLRequest` 변환 담당
- **Factory** — DI (`@Injected`, `AppContainer`). DEBUG 빌드에서 Mock provider 자동 주입
- **Nuke** — 이미지 비동기 로딩 & 캐싱
- **SPM** — 패키지 관리
- 빌드 설정에 **default actor isolation = MainActor** 적용됨 — `@Observable` 클래스에 `@MainActor`를 명시하지 않아도 메인 액터 격리됨. 리뷰 시 지적하지 말 것

## 프로젝트 구조 (현재)

```
Rephoto_iOS/
├── App/              — Rephoto_iOSApp(@main), ContentView (로그인 분기)
├── Core/
│   ├── Config/       — Config.swift, Config.xcconfig (BASE_URL)
│   ├── DIContainer/  — AppContainer (Factory 등록)
│   ├── Error/        — NetworkError, RepositoryError
│   └── NetworkAdapter/
│       ├── NetworkClient/ — NetworkClient(actor), TokenStoreProtocol, TokenPair, DefaultAuthenticationPolicy
│       ├── TokenRefreshService/ — TokenRefreshServiceImpl, MoyaNetworkAdapter
│       └── APITargetType, AuthSystemFactory
├── Features/             — 각 Feature는 Data/Domain/Presentation 3계층 동일 구조
│   ├── Home/             — 사진 그리드, 업로드, 사진 상세(태그/설명)
│   ├── Search/           — 자연어 검색(onSubmit 시점), 태그 앨범
│   ├── User/             — 로그인(LoginView), 세션(SessionStore)
│   ├── Settings/         — 설정 (현재 placeholder, #43에서 구현 예정)
│   └── RephotoTabView.swift — 탭 루트 뷰
├── Resource/         — Colors.xcassets, Assets.xcassets, 공용 컴포넌트(CTAButton)
└── Utilities/
    ├── Extensions/   — Date+Photo 등
    └── Keychain/     — KeychainTokenStore (actor)
```

- **제거된 기능**: PhotoCapture(카메라 촬영), 지도(Map), 휴지통, 도움말, 카카오 OAuth — 레거시에만 존재. 이 문서나 README에서 언급을 발견해도 부활시키지 말 것
- 리팩토링 전 레거시 코드: 형제 디렉토리 `../Rephoto_legacy` 에 보존

### 의존성 규칙

```
Presentation → Domain ← Data
  ViewModel → UseCase → Repository(Protocol) ← Repository(구현) → NetworkAdapter
```

- **Domain**: 순수 Swift, 외부 의존 없음
- **Data**: Domain Protocol 구현
- **Presentation**: UseCase만 의존 (Data 직접 참조 금지)
- **Core**: Feature 간 공유 인프라

## 아키텍처

- **Clean Architecture + MVVM** — View → ViewModel → UseCase → Repository
- **상태 관리**: `@Observable` 통일. 전역 인증 상태는 `SessionStore`가 소유 (화면 표현 상태는 각 ViewModel)
- **네비게이션**: TabView + NavigationStack (`navigationDestination(for:)` 값 기반)
- **인증**: KeychainTokenStore(actor) → NetworkClient(actor)가 Bearer 주입 + 401 감지 시 TokenRefreshService 호출 → 토큰 갱신 후 원래 요청 재시도. 갱신 실패 시 `SessionStore.forceLogout()`
- **DI**: Factory — `AppContainer`에 등록, 뷰에서 `@Injected`로 주입. Feature별 `UseCaseProvider` 프로토콜 + DEBUG용 Mock provider

## 빌드 & 테스트

```bash
# Xcode에서 빌드
Cmd + B

# 테스트 실행 (성능 벤치마크 포함 39개)
Cmd + U
```

- 성능 테스트 baseline은 `Rephoto_iOSTests/BASELINE_RESULTS.md`에 기록
- 테스트 가이드: `Rephoto_iOSTests/TEST_GUIDE.md`

## 커밋 컨벤션

```
feat: 새 기능
fix: 버그 수정
refactor: 리팩토링
test: 테스트 추가/수정
docs: 문서
chore: 설정, 빌드
```

PR 템플릿: `.github/pull_request_template.md`

## 네트워크 플로우

1. ViewModel → UseCase → Repository(프로토콜 구현)
2. Repository → NetworkClient(actor): `MoyaNetworkAdapter`가 `TargetType` → `URLRequest` 변환, URLSession으로 실행
3. NetworkClient가 Bearer 토큰 자동 주입, 401 응답 시 TokenRefreshService로 갱신 후 재시도 (동시 갱신은 단일 Task로 직렬화)
4. DTO → Domain Model 매핑은 Data 레이어(Repository)에서 수행 — Presentation은 Domain Model만 사용

## 사진 업로드 플로우

1. `PhotosPicker`(SwiftUI)로 사진 선택
2. `PhotoMetadataExtractor`가 EXIF/GPS 메타데이터 추출 — `TaskGroup`으로 병렬 처리
3. 업로드 전 이미지 다운샘플 + JPEG 압축 (ImageIO, #34)
4. S3 업로드 (`PhotosAPITarget.s3Upload`) → 메타데이터 일괄 저장 (`PhotosAPITarget.savePhotosBatch`)

---

## 리팩토링 계획 (개발 순서)

핵심 역량 (아키텍처, Concurrency, 모듈화, 테스트, CI/CD) 중심 포트폴리오 강화.

> **진행 현황 (2026-07 기준)**: Step 1~3 완료. Step 6 일부 완료(GitHub Actions 빌드 검증). Step 7 일부 완료(이미지 압축 #34).
> 현재 작업: SwiftUI 관찰 성능·뷰 구조 개선 + UI 마무리 — 열린 이슈 #35, #40~#43 참조. UI 작업 완료 후 포트폴리오 마무리 예정.

### Step 1. ✅ Clean Architecture + DI 전환 (완료)
**현재**: ViewModel 내부에서 MoyaProvider 직접 생성. 레이어 경계 없음. 테스트 시 stub 주입 불가.
**목표**:
- Feature별 Data/Domain/Presentation 3레이어 분리
- Domain 레이어에 UseCase 프로토콜 정의 → Implementations/ 에 구현체
- Repository 프로토콜 (Domain/Interfaces/) ← Repository 구현 (Data/) 분리
- DIContainer + UseCaseProvider 도입. ViewModel 생성자에서 UseCase 주입
- DTO → Domain Model 매핑을 Data 레이어에 격리 (Presentation은 Domain Model만 사용)

### Step 2. ✅ Token 관리 — Keychain + Actor (완료)
**현재**: UserDefaults에 토큰 직접 저장. 보안 취약 + 매 읽기/쓰기마다 디스크 I/O. race condition 가능성.
**목표**:
- KeychainTokenStore를 Swift actor로 구현 → thread-safe 보장
- 메모리 캐시 레이어 추가 (Keychain 접근 최소화)
- NetworkClient actor: 토큰 주입(AuthPlugin) + 401 감지 시 TokenRefreshService 호출 → 토큰 갱신 후 원래 요청 재시도
- AuthSystemFactory로 NetworkClient 조립 (TokenStore, RefreshService 의존성 주입)
- 토큰 만료/갱신/삭제 시나리오별 에러 처리 (로그아웃 유도 포함)

### Step 3. ✅ Swift Concurrency 전면 전환 (완료)
**현재**: `Data(contentsOf:)` 동기 로딩 + for loop 순차 처리. completion handler 혼재. 메인 스레드 블로킹.
**목표**:
- async/await 전면 도입. completion handler 전량 제거
- TaskGroup으로 사진 병렬 로딩 (HomeViewModel.handlePickedItems())
- @MainActor 격리: ViewModel의 UI 상태 변경을 메인 스레드 보장
- Sendable 준수: actor 경계를 넘는 데이터 타입 점검
- Task cancellation 처리: 화면 이탈 시 진행 중 작업 취소
- 네트워크 레이어 async화: MoyaProvider → async wrapper

### Step 4. Tuist + 멀티모듈 분리
**현재**: 단일 앱 타겟. .xcodeproj 직접 관리. Feature 간 암묵적 의존.
**목표**:
- Tuist manifest (Project.swift) 기반 프로젝트 생성
- Core 모듈: Network, DI, Navigation, Common (공유 인프라)
- Feature 모듈: Home, Search, User, Settings (각각 독립 프레임워크)
- 모듈 간 의존성 단방향 강제 (Feature → Core, Feature ✕→ Feature)
- Feature 모듈별 독립 빌드/테스트 가능하도록 타겟 분리

### Step 5. 테스트 커버리지 강화
**현재**: 성능 벤치마크 39개 존재. UseCase/ViewModel 단위 테스트 없음. UI 테스트 없음.
**목표**:
- Domain UseCase 단위 테스트: mock repository 주입하여 비즈니스 로직 검증
- ViewModel 상태 테스트: UseCase mock 주입 → 입력 이벤트 → 상태 변화 assertion
- Network 레이어 stub 테스트: Moya의 stubClosure 활용한 응답 시나리오 검증
- UI Test: 로그인 → 사진 목록 → 업로드 핵심 플로우 자동화
- 모듈별 독립 테스트 타겟 (Step 4 Tuist 구조 활용)

### Step 6. CI/CD (GitHub Actions + Fastlane)
**현재**: 수동 빌드/배포. 코드 스타일 규칙 미적용.
**목표**:
- GitHub Actions workflow: PR 생성 시 자동 빌드 + 전체 테스트 실행
- SwiftLint 자동 체크 (PR에 violation 코멘트)
- Fastlane lane: TestFlight beta 자동 배포
- 코드 커버리지 리포트 자동 생성 + PR에 첨부
- Tuist 기반 빌드이므로 `tuist generate` → `xcodebuild` 파이프라인

### Step 7. 성능 최적화
**현재**: DateFormatter 매번 생성, 이미지 원본 업로드, fetchPhotos() 전체 교체, 태그 배열 선형 검색.
**목표**:
- DateFormatter static 캐싱 또는 ISO8601DateFormatter 전환
- 업로드 전 이미지 압축 (quality 0.7~0.8)
- ETag/Last-Modified 기반 캐시 → 변경분만 diff 업데이트
- Dictionary 기반 O(1) 태그 조회 + 낙관적 업데이트 실패 시 롤백

### 의존성 흐름

```
Step 1 (Clean Arch + DI)
  └→ Step 2 (Token/Actor)
      └→ Step 3 (Concurrency)
          └→ Step 4 (Tuist 모듈화)
              ├→ Step 5 (테스트)
              └→ Step 6 (CI/CD)
                  └→ Step 7 (성능 최적화)
```
