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

8개 클래스 37개 측정. 회귀 판정 기준은 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md),
측정 방법과 스위트 정리 이력은 [`TEST_GUIDE.md`](TEST_GUIDE.md)에 있다.
(이 중 19개가 baseline 대조 대상이고, `HomeDerivedCollectionPerformanceTests` ·
`UploadMemoryBenchmark` · `DecodeVariantBenchTests`는 A/B 실측·측정 전용이라 카운트에서 제외한다.)

#### `DecodeVariantBenchTests` — 디코드 변형 대조 (4개)

**목적**: `UploadMemoryBenchmark`의 "풀디코드 대조군"이 이론값(4032×3024×4 ≈ 46.5MB)의
절반도 안 나오는 이유를 가른다. 가설 (a) `UIImage` lazy decoding으로 애초에 디코드하지 않음,
(b) 디코더가 서브샘플 YUV(1.5~2B/px)로 풂.

> **측정 완료 (2026-08-02, iPhone 14 Pro / iOS 27.0 beta / Release).** 결론: 대조군이 들고 있던
> 9.8MB는 픽셀 버퍼가 아니라 **출력 JPEG**이었다 — 풀사이즈 비트맵은 한 번도 상주하지 않는다.
> RGBA를 강제하면(C) 46.6MB로 이론값과 0.2% 일치한다. 상세는
> [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)의 DecodeVariantBenchTests 절.

| 테스트 메서드 | 변형 |
|---|---|
| `test_A_lazy_peakDelta` | `UIImage(data:)` 생성만 — 디코드 강제 없음 |
| `test_B_prepared_peakDelta` | `UIImage(data:).preparingForDisplay()` — UIKit이 고른 포맷으로 즉시 디코드 |
| `test_C_cgdraw_peakDelta` | `CGImageSource` → RGBA 8bit `CGContext` draw — 포맷을 못박은 강제 풀디코드 |
| `test_D_legacyControl_peakDelta` | 기존 대조군(`test_fullDecodeControl_peakDelta`)의 작업 구간 복사본 |

각 메서드가 5회 반복 후 `🧪 [B_prepared] max: 17.2MB  (runs: +17.2MB, +0.0MB, …)` 형태로 출력한다.
입력과 `FootprintSampler`는 `UploadMemoryBenchmark`와 공유한다 — 동일 조건을 보장하기 위해서다.
픽스처 탐색 경로와 스킵 조건도 같다 (아래 "실기기 + Release 벤치마크 측정" 참조).

##### 측정 설계에서 반드시 지켜야 할 세 가지

1인 개발이라 잊기 쉬운데, 이 세 가지를 어기면 수치가 조용히 틀린다.

**① 집계는 중앙값이 아니라 `max`.** `phys_footprint`는 `free()` 직후 바로 내려가지 않고,
프레임워크가 디코드 결과를 내부 캐시에 들고 있기도 한다. 그래서 2회차부터 보유·캐시된 페이지를
재사용해 delta가 **+0.0MB**로 찍힌다. 이 0.0은 "메모리를 안 썼다"가 아니라 **"못 쟀다"**이므로
중앙값을 쓰면 유일한 유효 샘플이 버려진다. (실제로 1차 측정에서 `B_prepared`가
17.2 → 0, 0, 0, 0으로 나와 중앙값 0.0MB라는 무의미한 값이 나왔다.)

**② 워밍업은 변형 자신이 아니라 64px 썸네일 디코드로.** JPEG 코덱 최초 사용 비용만 걷어내야 한다.
변형 자신을 미리 돌리면 그 변형의 디코드 캐시가 채워져 이후 측정이 전부 0.0이 된다.

**③ 변형마다 독립 메서드 + `-only-testing`으로 하나씩.** 한 프로세스에서 A→B→C→D를 연달아 돌리면
앞 변형이 남긴 상주 메모리가 뒤 변형의 baseline을 밀어올려 순서 의존성이 생긴다.

그 외: 측정 객체는 `withExtendedLifetime`으로 `stopPeak()` 시점까지 살려둔다
(Release `-O`에서 옵티마이저가 조기 해제해 피크를 놓치는 것을 막는다).

```bash
# 변형별로 하나씩 (권장). UDID는 xcrun devicectl list devices 로 확인
for M in test_A_lazy_peakDelta test_B_prepared_peakDelta \
         test_C_cgdraw_peakDelta test_D_legacyControl_peakDelta; do
  xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
    -testPlan Rephoto_Performance -configuration Release \
    -destination 'platform=iOS,id=<UDID>' \
    -only-testing:Rephoto_iOSTests/DecodeVariantBenchTests/$M \
    ENABLE_TESTABILITY=YES 2>&1 | grep 🧪
done
```

> **시뮬레이터 수치는 해석하지 않는다.** 시뮬레이터는 호스트 macOS의 소프트웨어 디코더를 쓰고
> Debug는 `-Onone`이라 실기기와 결과가 실제로 갈린다 — 이 프로젝트에서 이미 두 번 확인됐다
> (대조군 19MB↔9.8MB, maxPixelSize 정렬 효과는 시뮬레이터에서만 재현).
> 판정 근거로 쓸 수치는 **실기기 + Release**뿐이다. 측정 결과는 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md) 참조.

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
| `Rephoto_Performance.xctestplan` | 벤치마크 37케이스만 | 수동 · baseline 대조 |

플랜만 분리하고 **테스트 타겟은 1개**로 유지한다. 단일 앱 타겟이라 어느 쪽이든
`@testable import Rephoto_iOS`가 동일해서, 타겟을 쪼개도 격리 이득이 없기 때문이다.

성능 벤치마크를 PR 게이트에 넣지 않는 이유는 머신 편차가 신호보다 클 수 있기 때문이다.
같은 이유로 `XCTMemoryMetric`은 baseline 비교에서 제외했다 (상세: [`TEST_GUIDE.md`](TEST_GUIDE.md)).

로컬 실행:

```bash
# 단위 (CI와 동일). 아래 커버리지 명령이 읽을 결과 번들도 함께 남긴다.
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath TestResults.xcresult \
  -enableCodeCoverage YES

# 벤치마크
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Xcode에서는 `Cmd + U`로 활성 플랜을 실행한다. 플랜 전환은 스킴 에디터 > Test > Test Plans.

### 실기기 + Release 벤치마크 측정

시뮬레이터 + Debug 수치는 **판정 근거로 쓰지 않는다.** 시뮬레이터는 호스트 macOS의 코덱과
메모리 서브시스템을 쓰고 Debug는 `-Onone`이라, 특히 이미지 디코드 메모리는 실기기와 다르게 나온다.

```bash
# 1. 연결된 기기의 UDID 확인 (Reality 열이 physical인 항목)
xcrun devicectl list devices

# 2. 실행
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance \
  -configuration Release \
  -destination 'platform=iOS,id=<UDID>' \
  -only-testing:Rephoto_iOSTests/DecodeVariantBenchTests \
  -only-testing:Rephoto_iOSTests/UploadMemoryBenchmark \
  ENABLE_TESTABILITY=YES \
  -resultBundlePath DeviceRelease.xcresult

# 3. 🧪 로그만 추출
xcrun xcresulttool get log --path DeviceRelease.xcresult --type console | grep 🧪
```

**`ENABLE_TESTABILITY=YES`가 반드시 필요하다.** 프로젝트 Release 설정에는 이 값이 없어
기본값 `NO`이고, 그러면 `@testable import Rephoto_iOS`가 컴파일되지 않는다.
앱 타겟 Release 설정에 직접 켜면 출시 빌드까지 영향을 받으므로 **커맨드라인에서만** 넘긴다.
(부작용: 모듈 내부 심볼이 노출되어 일부 데드코드 제거·모듈 내 최적화가 억제된다.
디코드 작업은 시스템 프레임워크가 수행하므로 이 벤치마크에는 영향이 없다.)

**픽스처.** 실기기에는 `#filePath` 경로가 존재하지 않으므로 호스트의 `MockImagesReal/`을 읽을 수 없다.
`Rephoto_iOSTests/Performance/Fixtures/`에 카메라 원본을 두면 테스트 번들에 동봉되어 기기에서도 읽힌다
(타겟이 file-system synchronized group이라 폴더에 파일만 넣으면 되고 pbxproj 수정은 불필요).
`fixtureURL()`이 **번들 → 호스트 폴더** 순으로 찾으며, 실제로 어느 쪽을 썼는지는
`🧪 [입력] … [출처: …]` 로그에 찍힌다. 둘 다 없으면 자동 스킵.

> 앱 타겟 `Resources/`에는 넣지 말 것. 앱 번들 루트에 이미 `MockImages/IMG_9898.jpeg`가
> 평탄화되어 들어가 있어 파일명이 충돌한다(축소본 739KB — 원본 5,733KB와 다른 파일이다).
> 테스트 번들은 `Rephoto_iOSTests.xctest`로 분리되어 있어 충돌하지 않는다.

**측정 전 체크리스트** — 기기 상태가 수치를 흔든다.

- 저전력 모드 **끄기** (CPU/GPU 클럭 제한)
- 직전에 무거운 빌드를 돌렸다면 발열이 식을 때까지 대기 (thermal throttling)
- 화면 켜둔 채 잠금 해제 상태 유지
- 첫 실행은 워밍업으로 버리고 두 번째 실행부터 기록
- 측정 후 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md) 상단 「측정 환경」 템플릿을 채워 함께 기록

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
