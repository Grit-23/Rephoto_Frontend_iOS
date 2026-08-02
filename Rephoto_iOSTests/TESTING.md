# 테스트 정책

무엇을 테스트하고 무엇을 의도적으로 빼두었는지, 그리고 그 판단의 근거를 적는다.
커버리지 공백이 "누락"이 아니라 "판단 결과"임을 남기는 것이 이 문서의 목적이다.

벤치마크의 측정 방법과 수치는 [`TEST_GUIDE.md`](TEST_GUIDE.md) / [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)에 따로 있다.

---

## 무엇을 테스트하는가

### 네트워크 코어 — `Network/` (30 케이스)

| 스위트 | 검증 대상 |
|---|---|
| `NetworkClient` (9) | Bearer 주입 / 공개 경로 제외, 401 후 갱신·재시도, 갱신 실패 시 `onRefreshFailed`, **동시 401 20건에도 갱신 정확히 1회**(thundering-herd 방지) |
| `NetworkAdapter` (8) | `APITargetType` → `URLRequest` 조립. `.plain` / `.jsonEncodable` / `.multipart` 3경로와 헤더 우선순위 |
| `KeychainTokenStore` (6) | 저장·조회·덮어쓰기·삭제, service 격리, actor 직렬화 하 동시 접근 |
| `DefaultAuthenticationPolicy` (4) | 공개/보호 경로 판정. `/relogin` `/joint` 같은 유사 경로가 공개로 새지 않는지 |
| `PhotoRepository` (3) | 업로드 오케스트레이션 — 빈 입력 단락, 성공 시 S3 N회 + batch 1회, 부분 실패 시 batch 미호출 |

여기가 깨지면 화면 전체가 함께 죽는다. 최우선으로 둔다.

### API 계약 — `Features/*/Data/*APITargetTests.swift` (37 케이스)

`APITarget` 6종(`Photos` / `Tag` / `Description` / `Search` / `Album` / `User`)의
`path` · `method` · `task` · `headers`를 값으로 고정한다.

서버 스펙이 바뀌어도 컴파일은 통과하고 런타임에서야 깨지는 계층이다.
순수 함수라 실행 비용이 거의 0(6개 스위트 합계 20ms 미만)이면서 스펙 변경의 1차 방어선이 된다.

특히 값으로 묶어둘 이유가 있는 지점:

- `UserAPITarget` — `getUser` / `updateUser` / `deleteUser`가 `/users` 하나를 공유하고 method로만 갈린다
- `UserAPITarget` — `/login` `/join` `/auth/refresh`는 `DefaultAuthenticationPolicy`가 공개 경로로 판정하는 값이다. path가 틀어지면 토큰 주입 여부까지 함께 틀어진다
- `RefreshTokenRequestDTO` — 서버가 바디 키로 `Authorization`을 기대한다. 틀어지면 갱신이 조용히 실패하고 전 화면이 강제 로그아웃된다
- `PhotosAPITarget.s3Upload` — 유일하게 `headers`를 `nil`로 내려 어댑터가 boundary 포함 Content-Type을 설정하게 위임한다

### Presentation 상태 전이 — `Presentation/` (12 케이스)

| 스위트 | 검증 대상 |
|---|---|
| `SessionStoreTests` (8) | 토큰 유무에 따른 자동 로그인 복원, 로그인·로그아웃 상태 전이, 서버 로그아웃 실패해도 로컬 상태는 정리, 리프레시 실패 콜백 → 강제 로그아웃 |
| `LoginViewModelTests` (4) | 빈 입력 검증 시 세션 미호출, 성공·실패 시 `isLoading` / `errorMessage` 전이 |

### 성능 baseline — `Performance/`

7개 클래스 29개 측정. 회귀 판정 기준은 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md),
측정 방법과 스위트 정리 이력은 [`TEST_GUIDE.md`](TEST_GUIDE.md)에 있다.
(이 중 19개가 baseline 대조 대상이고, `HomeDerivedCollectionPerformanceTests`와
`UploadMemoryBenchmark`는 A/B 실측·측정 전용이라 카운트에서 제외한다.)

---

## 무엇을 아직 테스트하지 않는가 (의도적 제외)

**SwiftUI View 스냅샷** — 렌더링이 바뀔 때마다 유지비가 발생한다.
1인 개발 규모에서 ROI가 맞지 않는다고 판단해, ViewModel 레벨 상태 전이 검증으로 대체했다
(`SessionStoreTests` / `LoginViewModelTests`).

**UseCase 위임 계층** — 대부분 Repository 단순 위임이라 후순위.
분기 로직이 생기는 시점에 추가한다. 현재 유일한 후보는 `UploadPhotosUseCase`로,
`TaskGroup` 병렬 업로드와 부분 실패 처리를 담고 있다.
다만 그 오케스트레이션은 `PhotoRepositoryTests`가 이미 한 겹 덮고 있다.

**Search / Settings 피처의 ViewModel** — `SearchViewModel` / `AlbumViewModel`은
Home / User 대비 로직 밀도가 낮아 후순위. 두 피처의 `APITarget` 계약은 위에서 덮었다.
`Settings`는 아직 placeholder다.

**DTO 매핑** — `toDomain()`의 정상 경로는 `PhotoRepositoryTests`와 `DecodingPerformanceTests`가
간접적으로 지나간다. URL·날짜 파싱 실패 시 `RepositoryError.decodingFailed`로 떨어지는
경로는 아직 직접 검증하지 않았다.

---

## 프레임워크 선택 기준

기본은 **Swift Testing** (`@Suite` / `@Test` / `#expect`). 새 테스트는 여기에 쓴다.

**XCTest는 두 곳에만 남아 있다.**

1. `Performance/` — Swift Testing에 `measure(metrics:)` 대응 API가 없다. 이관 계획 없음.
2. `Presentation/` — XCTest로 먼저 작성됐다. 기술적 제약은 없고 이관 대상이지만,
   동작하는 테스트를 건드릴 이유가 약해 미뤄둔 상태다.

전역 상태(`handler` / `recordedRequests`)를 쓰는 `StubURLProtocol` 기반 스위트는
`StubURLProtocolSuites` 네임스페이스의 extension으로 선언한다.
Swift Testing은 스위트 간에도 병렬 실행하므로, `.serialized`를 컨테이너에 걸어
자식 전체에 재귀 적용시켜 직렬 실행을 보장한다 (`Support/TestHelpers.swift`).

같은 이유로 테스트 플랜의 `parallelizable`은 두 플랜 모두 `false`다.

---

## 실행

| 테스트 플랜 | 대상 | 시점 |
|---|---|---|
| `Rephoto_iOS.xctestplan` | 단위 테스트 79케이스 (성능 제외) | PR / push · CI 게이트 |
| `Rephoto_Performance.xctestplan` | 벤치마크 29케이스만 | 수동 · baseline 대조 |

플랜만 분리하고 **테스트 타겟은 1개**로 유지한다. 단일 앱 타겟이라 어느 쪽이든
`@testable import Rephoto_iOS`가 동일해서, 타겟을 쪼개도 격리 이득이 없기 때문이다.

성능 벤치마크를 PR 게이트에 넣지 않는 이유는 머신 편차가 신호보다 클 수 있기 때문이다.
같은 이유로 `XCTMemoryMetric`은 baseline 비교에서 제외했다 (상세: [`TEST_GUIDE.md`](TEST_GUIDE.md)).

로컬 실행:

```bash
# 단위 (CI와 동일)
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES

# 벤치마크
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Xcode에서는 `Cmd + U`로 활성 플랜을 실행한다. 플랜 전환은 스킴 에디터 > Test > Test Plans.

### 주의: `CODE_SIGNING_ALLOWED=NO`를 test에 붙이지 말 것

서명을 끄면 엔타이틀먼트가 없어 `KeychainTokenStore` 스위트 5개가
`errSecMissingEntitlement`(`-34018`)로 실패한다.
시뮬레이터는 ad-hoc 서명으로 충분하므로 CI의 `Test` 스텝에서는 이 플래그를 쓰지 않는다.
(`Build` 스텝에는 남겨둬도 무방하다.)

---

## 커버리지

CI가 `-enableCodeCoverage YES`로 실행하고, `xccov` 리포트를 Actions 요약에 출력한다.

```bash
xcrun xccov view --report --only-targets TestResults.xcresult
```

커버리지는 목표 수치를 정해두지 않았다. 위의 "무엇을 테스트하는가"에 적힌
우선순위대로 덮였는지를 보는 참고 지표로만 쓴다.
