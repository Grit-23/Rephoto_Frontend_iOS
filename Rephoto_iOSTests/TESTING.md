# 테스트 정책

무엇을 테스트하고 무엇을 의도적으로 빼두었는지, 그리고 그 판단의 근거를 적는다.
커버리지 공백이 "누락"이 아니라 "판단 결과"임을 남기는 것이 이 문서의 목적이다.

벤치마크의 측정 설계와 실기기 절차는 이 문서의 「성능 벤치마크」·「실기기 + Release 벤치마크 측정」에, 테스트 구성은 [`TEST_GUIDE.md`](TEST_GUIDE.md)에, 측정 수치는 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)에 있다.

백엔드는 운영이 종료됐다. 리팩토링은 로컬 목 서버 `mock_server.py`를 API 명세로 삼아 진행했고,
일부 경로·필드는 원 서버와 다르다. 아래 계약 테스트가 고정하는 것은 이 명세 기준의 클라이언트 선언이다.

---

## 무엇을 테스트하는가

### 네트워크 코어 — `Network/` (41 케이스)

| 스위트 | 검증 대상 |
|---|---|
| `NetworkClient` (16) | Bearer 주입 / 공개 경로 제외, 401 후 갱신·재시도, 갱신 실패 시 `onRefreshFailed`, **동시 401 20건에도 갱신 정확히 1회**(thundering-herd 방지), **실패 통지는 세션당 1회**(`hasNotifiedRefreshFailure` — 갱신 Task는 dedup으로 1개가 되지만 그 실패는 대기 중인 요청 전원에게 전달되므로 통지도 접는다) 및 **세션 복구 후 재통지**, 갱신 실패 유형별 토큰 삭제/유지, **로그아웃–갱신 경합**(응답 도착 후 logout → 저장 건너뜀 / 저장 단계 logout → 갱신 종료 뒤 clear) |
| `NetworkAdapter` (7) | `APITargetType` → `URLRequest` 조립. `.plain` / `.jsonEncodable` / `.multipart` 3경로와 헤더 우선순위 |
| `KeychainTokenStore` (6) | 저장·조회·덮어쓰기·삭제, service 격리, actor 직렬화 하 동시 접근(쌍의 index 일치로 검증) |
| `DefaultAuthenticationPolicy` (4) | 공개/보호 경로 판정. `/relogin` `/joint` 같은 유사 경로가 공개로 새지 않는지 |
| `PhotoRepository` (3) | 업로드 오케스트레이션 — 빈 입력 단락, 성공 시 S3 N회 + batch 1회, 부분 실패 시 batch 미호출 |
| `TokenRefreshServiceImpl` (3) | 실제 갱신 요청 계약 — `POST /auth/refresh` · JSON 헤더 · 바디 키 `Authorization`, 응답 → `TokenPair`, 비 2xx → `serverError(statusCode:)`. 백엔드 API 요청 중 유일하게 `NetworkAdapter`를 거치지 않는 요청(이미지 다운로드는 Nuke가 별도로 처리) |
| `UserRepository` (2) | 로그아웃 시 서버 호출 성공·실패 모두 로컬 토큰 삭제 |

여기가 깨지면 화면 전체가 함께 죽는다. 최우선으로 둔다.

### 클라이언트 엔드포인트 명세 — `Features/*/Data/*APITargetTests.swift` (35 케이스)

`APITarget` 6종(`Photos` / `Tag` / `Description` / `Search` / `Album` / `User`)의
`path` · `method` · `task` · `headers`를 값으로 고정한다.

선언이 바뀌어도 컴파일은 통과하고 런타임에서야 깨지는 계층이다.
순수 함수라 실행 비용이 거의 0(6개 스위트 합계 20ms 미만)인 테스트로 의도치 않은 변경을 잡는다.
서버 쪽 계약을 검증하는 것은 아니다 — 고정하는 것은 클라이언트가 보내기로 한 명세다.

특히 값으로 묶어둘 이유가 있는 지점:

- `UserAPITarget` — `getUser` / `updateUser` / `deleteUser`가 `/users` 하나를 공유하고 method로만 갈린다
- `UserAPITarget` — `/login` `/join`은 `DefaultAuthenticationPolicy`가 공개 경로로 판정하는 값이다. path가 틀어지면 토큰 주입 여부까지 함께 틀어진다
- 토큰 갱신 요청은 `APITarget`을 거치지 않고 `TokenRefreshServiceImpl`이 직접 보낸다. 서버가 기대하는 바디 키 `Authorization`은 `Network/TokenRefreshServiceTests`에서 고정한다 — 틀어지면 갱신이 조용히 실패하고 전 화면이 강제 로그아웃된다
- `PhotosAPITarget.s3Upload` — 유일하게 `headers`를 `nil`로 내려 어댑터가 boundary 포함 Content-Type을 설정하게 위임한다

### 응답 DTO 계약 — `Features/Search/Data/AlbumResponseDTOTests.swift` (6 케이스)

`GET /albums` 응답의 `coverImageUrl` · `photoCount`(#66 N+1 제거로 추가) 디코딩을 camelCase 그대로 고정한다.
`AlbumRepository`가 기본 설정 `JSONDecoder()`를 쓰므로 키 하나가 틀어지면 앨범 목록이 통째로 빈다.

### 업로드 전처리 — `Features/Home/Data/PhotoMetadataExtractorTests.swift` (1 케이스)

다운샘플 목표 크기 계산을 값으로 고정한다. 경계 정렬(4032 → 2016, 8064 → 2016)과
하한(#88 — 5712px는 정렬하면 1428px이라 2048px 요청), 상한 이하 원본·크기 미상 입력을 한 테스트의 인자로 돈다.
벤치마크(`UploadMemoryBenchmark`)도 같은 함수를 호출하므로 앱과 측정 경로가 갈라지지 않는다.

### Presentation 상태 전이 — `Presentation/` (12 케이스)

| 스위트 | 검증 대상 |
|---|---|
| `SessionStoreTests` (8) | 토큰 유무에 따른 자동 로그인 복원, 로그인·로그아웃 상태 전이, 서버 로그아웃 실패해도 로컬 상태는 정리, 리프레시 실패 콜백 → 강제 로그아웃 |
| `LoginViewModelTests` (4) | 빈 입력 검증 시 세션 미호출, 성공·실패 시 `isLoading` / `errorMessage` 전이 |

### 성능 벤치마크 — `Performance/`

3개 클래스 18개 측정(`HomeDerivedCollectionPerformanceTests` 11 · `UploadMemoryBenchmark` 3 · `DecodeVariantBenchTests` 4).
모두 A/B 실측·측정 전용이고 회귀 baseline(xcbaseline)은 두지 않는다. 측정 결과는 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md),
테스트 구성은 [`TEST_GUIDE.md`](TEST_GUIDE.md)에 있다.

#### `DecodeVariantBenchTests` — 디코드 변형 대조 (4개)

**목적**: `UploadMemoryBenchmark`의 "다운샘플 없는 대조군"이 이론값(4032×3024×4 ≈ 46.5MB)의
절반도 안 나오는 이유를 가른다. 가설 (a) `UIImage` lazy decoding으로 애초에 디코드하지 않음,
(b) 디코더가 서브샘플 YUV(1.5–2B/px)로 풂.

> **측정 완료 (2026-10-02, iPhone 14 Pro / iOS 27.2 beta / Release).** 결론: 대조군이 들고 있던
> 9.8MB는 픽셀 버퍼가 아니라 **출력 JPEG**이었다 — 풀사이즈 비트맵은 한 번도 상주하지 않는다.
> RGBA를 강제하면(C) 46.6MB로 이론값과 0.2% 일치한다. 상세는
> [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)의 DecodeVariantBenchTests 절.

| 테스트 메서드 | 변형 |
|---|---|
| `test_A_lazy_peakDelta` | `UIImage(data:)` 생성만 — 디코드 강제 없음 |
| `test_B_prepared_peakDelta` | `UIImage(data:).preparingForDisplay()` — UIKit이 고른 포맷으로 즉시 디코드 |
| `test_C_cgdraw_peakDelta` | `CGImageSource` → RGBA 8bit `CGContext` draw — 포맷을 못박은 강제 풀디코드 |
| `test_D_undownsampled_peakDelta` | 기존 대조군(`test_undownsampledReencode_peakDelta`)의 작업 구간 복사본 |

각 메서드가 5회 반복 후 `🧪 [B_prepared] max: 17.2MB  (runs: +17.2MB, +0.0MB, …)` 형태로 출력한다.
입력과 `FootprintSampler`는 `UploadMemoryBenchmark`와 공유한다 — 동일 조건을 보장하기 위해서다.
픽스처 탐색 경로와 스킵 조건도 같다 (아래 "실기기 + Release 벤치마크 측정" 참조).

##### 측정 설계에서 반드시 지켜야 할 세 가지

이 세 가지를 어기면 수치가 조용히 틀린다.

**① 집계는 중앙값을 쓰지 않는다.** `phys_footprint`는 `free()` 직후 바로 내려가지 않고,
프레임워크가 디코드 결과를 내부 캐시에 들고 있기도 한다. 그래서 2회차부터 보유·캐시된 페이지를
재사용해 delta가 **+0.0MB**로 찍힌다. 이 0.0은 "메모리를 안 썼다"가 아니라 **"못 쟀다"**이므로
중앙값을 쓰면 유일한 유효 샘플이 버려진다. (실제로 1차 측정에서 `B_prepared`가
17.2 → 0, 0, 0, 0으로 나와 중앙값 0.0MB라는 무의미한 값이 나왔다.)
대표값은 2회차 이후 값으로 하고, B처럼 2회차부터 0.0이면 1회차 값을 쓴다. 로그의 `max`는 C·D에서 콜드 런 값이라
대표값이 아니다(`BASELINE_RESULTS.md` 「집계 규칙」).

**② 워밍업은 변형 자신이 아니라 64px 썸네일 디코드로.** JPEG 코덱 최초 사용 비용만 걷어내야 한다.
변형 자신을 미리 돌리면 그 변형의 디코드 캐시가 채워져 이후 측정이 전부 0.0이 된다.

**③ 변형마다 독립 메서드 + `-only-testing`으로 하나씩.** 한 프로세스에서 A→B→C→D를 연달아 돌리면
앞 변형이 남긴 상주 메모리가 뒤 변형의 baseline을 밀어올려 순서 의존성이 생긴다.

그 외: 측정 객체는 `withExtendedLifetime`으로 `stopPeak()` 시점까지 살려둔다
(Release `-O`에서 옵티마이저가 조기 해제해 피크를 놓치는 것을 막는다).

실행 명령은 아래 「실기기 + Release 벤치마크 측정」에 있다.

> **시뮬레이터 수치는 해석하지 않는다.** 시뮬레이터는 호스트 macOS의 소프트웨어 디코더를 쓰고
> Debug는 `-Onone`이라 실기기와 결과가 실제로 갈린다 — 이 프로젝트에서 이미 두 번 확인됐다
> (대조군 19MB↔9.8MB, maxPixelSize 정렬의 메모리 효과는 시뮬레이터에서만 재현).
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

**Search 피처의 ViewModel · SettingsView** — `SearchViewModel` / `AlbumViewModel`은
Home / User 대비 로직 밀도가 낮아 후순위. Search의 `APITarget` 계약은 위에서 덮었다.
`SettingsView`(#52에서 User 피처로 합쳐짐)는 버전 표시와 로그아웃 확인만 있고 상태는 `SessionStore`에
위임하므로 `SessionStoreTests`가 덮는다.

**DTO 매핑** — `AlbumResponseDTO` 디코딩은 위에서 직접 고정했지만, 나머지 `toDomain()`의 정상 경로는
`PhotoRepositoryTests`가 간접적으로 지나간다. URL·날짜 파싱 실패 시 `RepositoryError.invalidResponse(detail:)`로
떨어지는 경로는 아직 직접 검증하지 않았다.

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
| `Rephoto_iOS.xctestplan` | 단위·계약 테스트 95케이스 (성능 제외) | PR / push · CI 게이트 |
| `Rephoto_Performance.xctestplan` | 벤치마크 18케이스만 | 수동 · 측정값 기록 |

플랜만 분리하고 **테스트 타겟은 1개**로 유지한다. 단일 앱 타겟이라 어느 쪽이든
`@testable import Rephoto_iOS`가 동일해서, 타겟을 쪼개도 격리 이득이 없기 때문이다.

성능 벤치마크를 PR 게이트에 넣지 않는 이유는 머신 편차가 신호보다 클 수 있기 때문이다.

로컬 실행:

단위 테스트(CI와 동일). 아래 커버리지 명령이 읽을 결과 번들도 함께 남긴다.

```bash
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath TestResults.xcresult \
  -enableCodeCoverage YES
```

벤치마크(시뮬레이터 — 수치는 판정에 쓰지 않는다. 실기기 절차는 아래 절):

```bash
xcodebuild test -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Xcode에서는 `Cmd + U`로 활성 플랜을 실행한다. 플랜 전환은 스킴 에디터 > Test > Test Plans.

### 실기기 + Release 벤치마크 측정

시뮬레이터 + Debug 수치는 **판정 근거로 쓰지 않는다.** 시뮬레이터는 호스트 macOS의 코덱과
메모리 서브시스템을 쓰고 Debug는 `-Onone`이라, 특히 이미지 디코드 메모리는 실기기와 다르게 나온다.

UDID는 `xcrun devicectl list devices`로 확인한다. 빌드는 한 번만 하고, 테스트는 **메서드 하나당 프로세스 하나**로 돌린다
(위 ③). 측정 줄은 xcodebuild 출력에서 바로 거른다 — 결과 번들의 `xcresulttool get log --type console`에는 남지 않는다.

```bash
xcodebuild build-for-testing -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance -configuration Release \
  -destination 'platform=iOS,id=<UDID>' -derivedDataPath <DD> ENABLE_TESTABILITY=YES

xcodebuild test-without-building -xctestrun <DD>/Build/Products/<…>.xctestrun \
  -destination 'platform=iOS,id=<UDID>' \
  -only-testing:Rephoto_iOSTests/DecodeVariantBenchTests/test_B_prepared_peakDelta \
  2>&1 | grep -E "🧪|run[0-9]:|measured"
```

`-only-testing`의 대상만 바꿔 `DecodeVariantBenchTests` · `UploadMemoryBenchmark` · `HomeDerivedCollectionPerformanceTests`의
메서드를 하나씩 돌린다. 실제로 쓴 반복 횟수·폴더 구조는 측정 원문 README의 「재현 명령」에 있다 —
업로드 전처리는 [`2026-10-03_iPhone14Pro_15photos`](../docs/benchmarks/2026-10-03_iPhone14Pro_15photos/README.md),
디코드 변형·파생 컬렉션은 [`2026-10-02_iPhone14Pro_iOS27.2b`](../docs/benchmarks/2026-10-02_iPhone14Pro_iOS27.2b/README.md).
zsh에 붙여 넣을 때는 `#` 주석 줄을 빼야 한다(대화형 zsh는 기본적으로 주석을 해석하지 않는다).

**`ENABLE_TESTABILITY=YES`가 반드시 필요하다.** 프로젝트 Release 설정에는 이 값이 없어
기본값 `NO`이고, 그러면 `@testable import Rephoto_iOS`가 컴파일되지 않는다.
앱 타겟 Release 설정에 직접 켜면 출시 빌드까지 영향을 받으므로 **커맨드라인에서만** 넘긴다.
(부작용: 모듈 내부 심볼이 노출되어 일부 데드코드 제거·모듈 내 최적화가 억제된다.
디코드 작업은 시스템 프레임워크가 수행하므로 디코드 벤치마크(`UploadMemoryBenchmark` · `DecodeVariantBenchTests`)에는 영향이 없다.)

**픽스처.** 실기기에는 `#filePath` 경로가 존재하지 않으므로 호스트의 `MockImagesReal/`을 읽을 수 없다.
`Rephoto_iOSTests/Performance/Fixtures/`에 원본 해상도 사진을 두면 테스트 번들에 동봉되어 기기에서도 읽힌다
(타겟이 file-system synchronized group이라 폴더에 파일만 넣으면 되고 pbxproj 수정은 불필요).
**번들 → 호스트 폴더** 순으로 찾으며, 실제로 어느 쪽을 썼는지는 `🧪 [입력] … [출처: …]` 로그에 찍힌다. 둘 다 없으면 자동 스킵.
`UploadMemoryBenchmark`의 두 측정은 `fixtureURLs()`로 **폴더의 사진을 전부** 돌고, `DecodeVariantBenchTests`와 대조군은 `fixtureURL()`로 **가장 큰 한 장**만 쓴다.

> 앱 타겟 `Resources/`에는 넣지 말 것. 앱 번들 루트에 이미 `MockImages/IMG_9898.jpeg`가
> 평탄화되어 들어가 있어 파일명이 충돌한다(축소본 722KB — 원본 5,733KB와 다른 파일이다).
> 테스트 번들은 `Rephoto_iOSTests.xctest`로 분리되어 있어 충돌하지 않는다.

**측정 전 체크리스트** — 기기 상태가 수치를 흔든다.

- 저전력 모드 **끄기** (CPU/GPU 클럭 제한)
- 직전에 무거운 빌드를 돌렸다면 발열이 식을 때까지 대기 (thermal throttling)
- 화면 켜둔 채 잠금 해제 상태 유지
- 첫 실행은 워밍업으로 버리고 두 번째 실행부터 기록
- 측정일·기기·iOS 빌드 번호·빌드 구성·반복 횟수를 수치와 함께 기록 ([`BASELINE_RESULTS.md`](BASELINE_RESULTS.md) 「측정 환경」 형식)

### 주의: `CODE_SIGNING_ALLOWED=NO`를 test에 붙이지 말 것

서명을 끄면 엔타이틀먼트가 없어 `KeychainTokenStore` 스위트 6개가
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
