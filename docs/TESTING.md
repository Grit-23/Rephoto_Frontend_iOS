# 테스트 가이드

Tuist 워크스페이스(`Rephoto/`) 기준이다. 성능 측정값은 [BASELINE_RESULTS.md](BASELINE_RESULTS.md)에 있다.

## 한눈에 보기

| 종류 | 개수 | 도구 | 언제 도나 | 명령 |
|---|---|---|---|---|
| 단위 · 계약 테스트 | 200 | Swift Testing | PR마다 (`tuist.yml`) | `make test` |
| 성능 벤치마크 | 18 | XCTest | 수동 | `make perf` |

## 무엇을 테스트하나

| 모듈 | 개수 | 지키는 것 |
|---|---|---|
| Core / NetworkAdapter | 43 | 토큰 주입과 공개 경로 구분, 401 → 갱신 → 재시도, 동시 401 20건에 갱신 1회, 갱신 실패 통지 1회, 세션이 바뀐 뒤 늦게 온 응답 처리, Keychain 저장 · 삭제 실패 시 기존 토큰 보존, 요청 조립(plain · JSON · multipart) |
| Shared / Foundation | 15 | 에러를 `AppError`로 정규화(취소 · 디코딩 · 계층 에러), `Loadable` 상태 |
| Shared / DesignSystem | 9 | `ErrorHandler` — 취소는 무시, 인증 만료는 세션 만료 훅 호출, 재시도 동작 교체 |
| Domain / Photo | 33 | 엔드포인트 명세(사진 · 설명 · 검색), 응답 → 모델 매핑, 디코딩이 메인 스레드 밖에서 도는지, 업로드 순서(S3 N회 → 저장 1회, 일부 실패 시 저장 안 함), 다운샘플 목표 크기 |
| Domain / Tag | 14 | 엔드포인트 명세, 응답 → 모델 매핑 |
| Domain / Album | 13 | 엔드포인트 명세, 응답 디코딩(`coverImageUrl` · `photoCount`) |
| Domain / User | 23 | 엔드포인트 명세, 로그인 시 토큰 저장, 로그아웃, 갱신 실패 핸들러 |
| Feature / Home | 17 | 사진 목록 상태 전이(성공 · 빈 목록 · 실패 · 취소 · 재시도), 태그 3개 제한, 사진 삭제 |
| Feature / Search | 20 | 검색 상태 전이, 늦게 도착한 결과가 최신 결과를 덮지 않는지, 앨범 목록 · 앨범 사진 |
| Feature / User | 13 | 세션 복원 · 로그인 · 로그아웃, 강제 로그아웃, 로그인 입력 검증 |

우선순위는 네트워크 코어가 가장 높다. 여기가 깨지면 모든 화면이 함께 죽는다.
엔드포인트 명세 테스트는 서버가 아니라 클라이언트가 보내기로 한 값(`path` · `method` · 바디)을 고정한다. 선언이 바뀌어도 컴파일은 통과하고 실행해야 깨지는 계층이라 값으로 묶어 둔다.

### 일부러 테스트하지 않는 것

| 대상 | 이유 |
|---|---|
| SwiftUI View 스냅샷 · UI Test | 화면이 바뀔 때마다 유지비가 든다. ViewModel의 상태 전이 테스트로 대신한다 |
| 단순 위임 UseCase 일부(태그 추가 · 수정 · 삭제, 사진 삭제 · 업로드, 설명 조회) | Repository 호출을 그대로 넘기는 코드다. 업로드 순서는 `PhotoRepositoryTests`가 덮는다 |

## 실행

`Rephoto/`에서 실행한다.

```bash
make test                                       # 단위 · 계약 테스트 200개 (CI와 동일)
make test SCHEME=PhotoDomain                    # 모듈 하나만
make test RESULT_BUNDLE=TestResults.xcresult    # 커버리지용 결과 번들까지
make perf                                       # 성능 벤치마크 18개 (시뮬레이터)
```

Xcode에서는 `Rephoto` 스킴에서 `Cmd + U`가 단위 테스트만 돌린다. 성능 벤치마크는 Product → Test Plan → `Rephoto_Performance`로 바꿔서 돌린다.

### 커버리지

```bash
xcrun xccov view --report --only-targets TestResults.xcresult
```

CI는 이 리포트를 Actions 요약에 출력한다. 목표 수치는 두지 않고, 위 표의 우선순위대로 덮였는지 보는 참고 지표로 쓴다.

## 성능 벤치마크

`Rephoto/Projects/App/PerformanceTests/`에 있고 `RephotoPerformanceTests` 타깃으로 묶인다. 실기기는 앱 안에서 도는 테스트만 실행할 수 있어서 모듈 테스트가 아니라 Rephoto 앱에 붙였다.
회귀 기준값(xcbaseline)은 두지 않는다. 기기와 OS에 따라 값이 달라 PR 게이트로 쓸 수 없기 때문이다.

| 클래스 | 개수 | 재는 것 |
|---|---|---|
| `UploadMemoryBenchmark` | 3 | 업로드 전처리의 출력 크기 · 처리 시간. 현재 경로(`extract`), 다운샘플 없는 대조군, 목표 크기 옵션 실험(A–D) |
| `DecodeVariantBenchTests` | 4 | 디코드 방식별 메모리 증가 — 대조군이 풀디코드인지 가리는 실험 |
| `HomeDerivedCollectionPerformanceTests` | 11 | 홈 화면 사진 목록 계산 — 계산 프로퍼티 vs didSet 캐싱 |

### 입력 사진

`UploadMemoryBenchmark`와 `DecodeVariantBenchTests`는 원본 해상도 사진이 필요하다. 없으면 실패가 아니라 건너뛴다.

- 위치: `Rephoto/Projects/App/PerformanceTests/Fixtures/`. 넣거나 뺀 뒤 `make generate`를 다시 돌린다.
- **개인 사진(GPS 포함)이라 커밋하지 않는다.** `.gitignore`로 막혀 있다.
- 앱이 사진 선택기에서 실제로 받는 데이터여야 한다. 아이폰 원본(HEIC)이나 Mac에서 변환한 JPEG는 조건이 다른 입력이다. 만드는 방법은 [2026-10-03 기록](benchmarks/2026-10-03_iPhone14Pro_15photos/README.md)에 있다.
- 시뮬레이터에서는 레포 루트의 `MockImagesReal/`도 읽는다.

### 실기기에서 재기

시뮬레이터 값은 동작 확인용이다. 기록할 값은 실기기 + Release로 잰다. 기기 ID는 `xcodebuild -workspace Rephoto.xcworkspace -scheme Rephoto -showdestinations`로 확인한다.

```bash
DD=~/Library/Developer/RephotoPerf      # 레포 밖에 둔다 (iCloud 경로 안에서는 CodeSign이 실패한다)

xcodebuild build-for-testing -workspace Rephoto.xcworkspace -scheme Rephoto \
  -testPlan Rephoto_Performance -configuration Release \
  -destination "platform=iOS,id=<기기 ID>" -derivedDataPath $DD ENABLE_TESTABILITY=YES

xcodebuild test-without-building -xctestrun $DD/Build/Products/*.xctestrun \
  -destination "platform=iOS,id=<기기 ID>" \
  -only-testing:RephotoPerformanceTests/UploadMemoryBenchmark/test_current_downsampleExtract_peakDelta \
  2>&1 | grep -E "입력|run[0-9]:|measured|error|\*\* TEST"
```

`ENABLE_TESTABILITY=YES`는 Release에서 `@testable import`를 쓰기 위한 것이다. 출시 빌드에 영향이 가지 않게 커맨드라인에서만 넘긴다.

### 잴 때 지킬 것

| 규칙 | 이유 |
|---|---|
| 테스트 하나당 프로세스 하나(`-only-testing`) | 앞 테스트가 남긴 메모리가 뒤 테스트의 기준선을 밀어 올린다 |
| 메모리 값에 중앙값을 쓰지 않는다 | 2회차부터는 캐시 때문에 증가분이 0으로 찍힌다. 0은 "안 썼다"가 아니라 "못 쟀다"다 |
| 시간은 1회차를 버린다 | 첫 실행에는 코덱 준비 비용이 섞인다 |
| 저전력 모드를 끄고, 무거운 빌드 직후에는 식을 때까지 기다린다 | 발열과 전력 제한이 시간을 흔든다 |
| 측정일 · 기기 · OS 빌드 · 반복 횟수를 값과 함께 적는다 | 조건이 없는 숫자는 다시 확인할 수 없다 |

## 작성 규칙

- 새 테스트는 Swift Testing(`@Test("한글 설명")`)으로 쓴다. XCTest는 `measure`가 필요한 성능 벤치마크에만 쓴다.
- 네트워크 스텁은 `NetworkAdapterTesting`의 `StubURLProtocol`을 쓴다. 전역 상태를 쓰므로 스위트를 `.serialized`로 직렬화한다.
- Mock은 Interface 프로토콜에 `/// @mockable`을 붙이면 `make generate`가 만든다.
