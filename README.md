# Rephoto iOS

> 고령층을 위한 AI 사진 찾기 앱 — 사진을 올리면 AI가 자동으로 설명·태그를 달고, 자연어로 검색할 수 있습니다.

<br>

## 프로젝트 개요

- **기간**: 2025.04 ~ 2025.08
- **인원**: iOS 1 · Backend 2 · AI 1 (총 4명)
- **담당**: iOS 앱 **단독 개발** — 아키텍처 설계부터 네트워크 레이어·전체 화면 구현까지
- **이력**: 오픈소스 개발자대회 출품

<br>

## 주요 기능

| 기능 | 설명 |
|------|------|
| 📷 **사진 업로드 + AI 분석** | 사진을 올리면 서버 AI(VLM)가 자동으로 설명·태그를 생성 |
| 🔍 **자연어 검색** | "바다에서 찍은 사진"처럼 문장으로 사진을 검색 |
| 🗂 **태그 기반 앨범** | 생성된 태그로 사진을 자동 분류해 앨범으로 제공 |
| ⚠️ **개인정보 감지 경고** | 개인정보 및 문서가 포함된 사진 분류 표시 |

<br>

## 기술 스택

| 구분 | 사용 기술 |
|------|-----------|
| **언어 / UI** | Swift, SwiftUI |
| **아키텍처** | Clean Architecture (Data / Domain / Presentation), MVVM |
| **비동기** | Swift Concurrency (`async/await`, `actor`) |
| **DI** | [Factory](https://github.com/hmlongco/Factory) |
| **네트워크** | URLSession 기반 자체 네트워크 레이어 + Moya `TargetType` |
| **보안** | Keychain |
| **이미지** | [Nuke](https://github.com/kean/Nuke) |
| **패키지 관리** | Swift Package Manager |

<br>

## 사용 기술

### 1. actor 기반 인증 네트워크 레이어
- **`NetworkClient` (actor)** — 401 응답 시 토큰을 자동 갱신·재요청. 여러 요청이 동시에 갱신을 트리거해도 단일 `Task`로 직렬화해 중복 갱신과 race condition을 차단합니다.
- **`KeychainTokenStore` (actor)** — Access/Refresh 토큰을 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` 옵션으로 Keychain에 저장하고, refresh 저장 실패 시 access를 롤백해 부분 저장을 방지합니다.

### 2. Moya 의존성 점진적 제거
- 엔드포인트 선언은 Moya `TargetType` DSL로 유지하되, 실제 네트워킹은 `URLSession` 기반 자체 `NetworkClient`로 교체했습니다.
- `MoyaNetworkAdapter`가 `TargetType` → `URLRequest` 변환과 멀티파트 인코딩을 직접 담당해, Alamofire 런타임 의존을 제거하면서도 마이그레이션 비용을 분산했습니다.

### 3. TaskGroup 기반 병렬 업로드
- 여러 장의 사진을 `withThrowingTaskGroup`으로 S3에 동시 업로드한 뒤, 메타데이터를 한 번에 batch 저장합니다.

### 4. Factory DI + DEBUG Mock 자동 주입
- `Factory`로 의존성을 등록하고, DEBUG 빌드에서는 `UseCaseProvider`를 Mock으로 자동 교체해 SwiftUI Preview·단위 테스트를 실제 네트워크 없이 격리합니다.

<br>

## 프로젝트 구조

기능(Feature) 단위로 폴더를 나누고, 각 기능을 Data / Domain / Presentation 3계층으로 분리했습니다.

```
Rephoto_iOS/
├── App/              # 앱 진입점 (@main, ContentView)
├── Core/             # 공통 인프라 (DI, 네트워크, 에러)
├── Features/
│   ├── Home/         # 사진 목록·업로드·태그·설명
│   ├── Search/       # 자연어 검색·앨범
│   ├── User/         # 로그인·인증
│   └── Settings/     # 설정·휴지통·도움말
│       ├── Data/         # DTO · Repository · API Target
│       ├── Domain/       # UseCase · Model · Interface
│       └── Presentation/ # View · ViewModel
└── Utilities/        # Keychain, Extensions
```

<br>

## CI

- `main` 브랜치 push / PR 시 GitHub Actions가 자동 빌드 검증을 수행합니다.
- 실행 환경: `macos-26`, `iPhone 17 Pro` 시뮬레이터
- SPM 캐시 적용으로 빌드 시간을 단축하고, 동일 브랜치 중복 실행은 자동 취소합니다.

<br>

## License

[MIT License](LICENSE) © 2025 Grit-23
