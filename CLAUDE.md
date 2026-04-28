# Rephoto iOS

사진 위치 기반 관리 앱. SwiftUI + MVVM.

## 기술 스택

- **Swift 5 / SwiftUI** (iOS 26.0+)
- **Moya** — HTTP 네트워킹 (Alamofire 기반)
- **Nuke** — 이미지 비동기 로딩 & 캐싱
- **SPM** — 패키지 관리

## 프로젝트 구조 (현재 — 레거시)

```
Rephoto_iOS/
├── App/              # 진입점 (Rephoto_iOSApp, ContentView)
├── Features/
│   ├── Home/         # 사진 갤러리, 업로드, 앨범
│   ├── Search/       # 검색 (디바운스 300ms)
│   ├── Settings/     # 설정, 휴지통
│   ├── PhotoCapture/ # 카메라 촬영
│   └── User/         # 로그인, 회원가입, 카카오 OAuth
├── Network/
│   ├── Targets/      # Moya API 타겟 (User, Photos, Search, Tag, Album, Description)
│   └── DTOs/         # 요청/응답 모델 (도메인별 분류)
└── Resource/         # Config.xcconfig (baseURL 등)
```

## 프로젝트 구조 (목표 — Clean Architecture)

```
Rephoto_iOS/
├── App/                          — 엔트리 포인트 (Rephoto_iOSApp, ContentView)
├── Core/
│   ├── Config/                   — Config.swift (Info.plist에서 BASE_URL 로드)
│   ├── Common/Extensions/        — DateFormatter 등 공통 확장
│   ├── DIContainer/              — DIContainer, UseCaseProvider
│   ├── Error/                    — RepositoryError
│   ├── Navigation/               — NavigationDestination, PathStore, NavigationRouter, NavigationRoutingView
│   └── NetworkAdapter/
│       ├── Base/                 — BaseTargetType, APIResponse, EmptyResult
│       ├── NetworkClient/        — NetworkClient(actor), TokenStore, TokenPair, DefaultAuthenticationPolicy
│       ├── TokenRefreshService/  — TokenRefreshServiceImpl, MoyaNetworkAdapter
│       └── AuthDependencies.swift — AuthSystemFactory (NetworkClient 조립 팩토리)
├── Features/
│   ├── Home/
│   │   ├── Data/                 — DTO, PhotosTarget(Moya), HomeRepository
│   │   ├── Domain/
│   │   │   ├── Interfaces/       — HomeRepositoryProtocol
│   │   │   ├── Models/           — Photo, Album, HomeModel
│   │   │   └── UseCases/         — 각 UseCase 프로토콜 및 Implementations/
│   │   └── Presentation/         — HomeView, HomeViewModel, Components/
│   ├── Search/
│   │   ├── Data/                 — DTO, SearchTarget(Moya), SearchRepository
│   │   ├── Domain/
│   │   │   ├── Interfaces/       — SearchRepositoryProtocol
│   │   │   ├── Models/           — SearchResult
│   │   │   └── UseCases/
│   │   └── Presentation/         — SearchView, SearchViewModel
│   ├── PhotoCapture/
│   │   ├── Data/                 — S3Target, CaptureRepository
│   │   ├── Domain/
│   │   │   ├── Interfaces/
│   │   │   ├── Models/           — PhotoMetadata
│   │   │   └── UseCases/
│   │   └── Presentation/         — PhotoCaptureView, PhotoCaptureViewModel
│   ├── Settings/
│   │   ├── Data/
│   │   ├── Domain/
│   │   └── Presentation/         — SettingsView, TrashView
│   ├── Auth/
│   │   ├── Data/                 — AuthTarget, AuthRepository
│   │   ├── Domain/
│   │   │   ├── Interfaces/       — AuthRepositoryProtocol
│   │   │   ├── Models/           — User
│   │   │   └── UseCases/         — LoginUseCase, LogoutUseCase
│   │   └── Presentation/         — LoginView, LoginViewModel, SignupView
│   └── Tab/
│       └── Presentation/         — RephotoTabView (탭 루트 뷰)
├── Resources/
│   └── EnvironmentKey/           — DIEnvironmentKey.swift
└── Utilities/
    └── Keychain/                 — KeychainTokenStore (actor)
```

### Clean Architecture 의존성 규칙

```
Presentation → Domain ← Data
     ↓            ↑        ↓
  ViewModel → UseCase → Repository(Protocol)
                           ↑
                    Repository(구현) → NetworkAdapter
```

- **Domain**은 어떤 레이어도 import하지 않음 (순수 Swift)
- **Data**는 Domain의 Interfaces(Protocol)를 구현
- **Presentation**은 Domain의 UseCase만 의존 (Data 직접 참조 금지)
- **Core**는 Feature 간 공유되는 인프라 (네트워크, DI, 네비게이션)
- 각 Feature가 자체 Data/Domain/Presentation을 가짐 (Feature별 독립)

## 아키텍처

- **Clean Architecture + MVVM** — View → ViewModel → UseCase → Repository
- **상태 관리**: `@Observable` 통일
- **네비게이션**: TabView + NavigationStack + PathStore (스택 기반 라우팅)
- **인증**: KeychainTokenStore (actor) → NetworkClient → AuthPlugin (Bearer 주입) → TokenRefreshService (401 자동 리프레시)
- **DI**: DIContainer + UseCaseProvider + EnvironmentKey (SwiftUI Environment 주입)

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

1. ViewModel → MoyaProvider.request(target)
2. AuthPlugin → Bearer 토큰 자동 주입
3. 401 응답 → AuthedProvider가 /auth/refresh 호출 → 토큰 갱신 후 재시도
4. DTOs → Domain Model 매핑 (예: `PhotoResponseDto.toHomeModel()`)

## 사진 업로드 플로우

1. PHPickerViewController로 사진 선택
2. EXIF/GPS 메타데이터 추출 (CGImageSource)
3. S3 multipart upload (PhotosAPITarget.s3Upload)
4. 메타데이터 일괄 저장 (PhotosAPITarget.savePhotosBatch)

---

## 리팩토링 계획

### #1 의존성 관리 (Dependency Injection)
**현재**: ViewModel 내부에서 MoyaProvider 직접 생성. 테스트 시 stub 주입 불가.
**목표**: Protocol 기반 DI 컨테이너 도입. ViewModel 생성자에서 의존성 주입.
**범위**: 모든 ViewModel, Network Provider

### #2 Token 관리 로직 수정
**현재**: UserDefaults에 직접 저장. 보안 취약 + 매 읽기/쓰기마다 디스크 I/O.
**목표**: Keychain 저장 + 메모리 캐시 레이어 추가.
**범위**: TokenStore, AuthPlugin, AuthedProvider
**성능 테스트**: `TokenPerformanceTests` (save/read/hasTokens/refresh cycle/clear)

### #3 사진 관리 개선
**현재**:
- `toHomeModel()`에서 매번 DateFormatter 새로 생성 (성능 병목)
- 원본 JPEG quality 1.0 그대로 S3 업로드 (불필요한 대역폭)

**목표**:
- DateFormatter static 캐싱 또는 ISO8601DateFormatter 사용
- 업로드 전 적절한 압축률 적용 (quality 0.7~0.8)

**범위**: PhotoResponseDto.toHomeModel(), HomeViewModel 업로드 로직
**성능 테스트**: `DateFormatterPerformanceTests`, `DecodingPerformanceTests`, `MappingPerformanceTests`, `ImageCompressionPerformanceTests`

### #4 사진 로딩 비동기 처리
**현재**: `Data(contentsOf:)` 동기 로딩 + for loop 순차 처리. 메인 스레드 블로킹.
**목표**: async/await + TaskGroup 병렬 로딩. 백그라운드 스레드 처리.
**범위**: HomeViewModel.handlePickedItems(), PHCaptureImageView
**성능 테스트**: `PhotoLoadingPerformanceTests`, `MemoryPerformanceTests`

### #5 캐시 기반 API 호출 최적화
**현재**: fetchPhotos() 호출 시 매번 전체 목록 디코딩 + 매핑 + 배열 전체 교체.
**목표**: ETag/Last-Modified 기반 캐시. 변경분만 업데이트 (diff 적용).
**범위**: HomeViewModel.fetchPhotos(), 네트워크 레이어 캐시 미들웨어
**성능 테스트**: `CacheHashPerformanceTests`

### #6 사진 정보 수정
**현재**: 태그 추가/삭제 시 배열 선형 검색 + 교체. 낙관적 UI 업데이트 후 실패 시 롤백 없음.
**목표**: Dictionary 기반 O(1) 조회. 낙관적 업데이트 실패 시 롤백 처리.
**범위**: PhotoInfoViewModel (태그 CRUD, 설명 수정)
**성능 테스트**: `PhotoInfoPerformanceTests`

### #7 사용자 피드백
**현재**: 에러 발생 시 사용자에게 알림 없음. print 로그만 존재.
**목표**: Toast/Alert 기반 에러 표시. 네트워크 오류 재시도 UI.
**범위**: 전체 ViewModel 에러 처리 흐름

### 리팩토링 우선순위

| 순위 | 항목 | 이유 |
|---|---|---|
| 1 | #1 의존성 관리 | 이후 모든 리팩토링의 기반 |
| 2 | #2 Token 관리 | 보안 이슈, 앱 전반에 영향 |
| 3 | #3 사진 관리 | 성능 병목 (DateFormatter), 대역폭 낭비 |
| 4 | #4 비동기 로딩 | UX 직결 (UI 블로킹) |
| 5 | #5 캐시 최적화 | 불필요한 네트워크 호출 감소 |
| 6 | #6 사진 정보 | 데이터 일관성 |
| 7 | #7 피드백 | UX 개선 |
