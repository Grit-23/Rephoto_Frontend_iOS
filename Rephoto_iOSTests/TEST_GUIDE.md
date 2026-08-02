# Rephoto iOS 성능 벤치마크 테스트 가이드

리팩토링 전후 성능을 비교하기 위한 벤치마크 테스트.

> 2026-07-23 스위트 정리: 소임을 다한 레거시 재현 테스트(`DateFormatter`, `PhotoLoading`, `CacheHash`, `ImageCompression`)와 노이즈성 소규모 테스트, 정보량이 적은 중간 티어(500급)를 삭제했다. 데이터 규모는 100(일반) / 1000(실사용 상한) 2단계만 유지.
> `XCTMemoryMetric`은 `MemoryPerformanceTests`에만 유지 — Memory Physical baseline이 0.0kB로 기록되거나 peak가 프로세스 전체값이라 번들 리소스 추가만으로 밀리는 문제가 있어, 나머지 테스트에서는 제거했다.

---

## 리팩토링 후 비교 방법

1. 리팩토링한 코드에서 `Cmd + U` 실행
2. Xcode Test Report에서 baseline 대비 변화율(%) 자동 표시
   - 초록: 성능 개선
   - 빨강: 성능 저하

> 모든 테스트는 **현재 코드 방식만** 측정합니다. 리팩토링 후 코드가 바뀌면 같은 테스트의 결과가 달라지므로 자동으로 비교됩니다.

### 실행 환경 기록

벤치마크 결과를 비교할 때는 동일한 환경에서 실행해야 합니다. 테스트 실행 전 아래 항목을 기록해두세요.

| 항목 | 값 |
|---|---|
| Device / Simulator | (예: iPhone 16 Pro Simulator) |
| OS Version | (예: iOS 18.4) |
| Xcode Version | (예: 16.4) |
| Build Configuration | Debug |
| 병렬 실행 | OFF (직렬) |

---

## 테스트 파일 구성 (19개 테스트)

### `Support/MockDataFactory.swift`
공용 Mock 데이터 생성 팩토리.

---

### `DecodingPerformanceTests.swift`

| 테스트 | 측정 대상 |
|---|---|
| `test_decodePhotos_100` | 서버 응답 JSON → PhotoResponseDTO 디코딩 100개 |
| `test_decodePhotos_1000` | 1000개 (스트레스) |
| `test_decodeSearchResponse_200` | 검색 결과 200개 |

---

### `MappingPerformanceTests.swift`

| 테스트 | 측정 대상 |
|---|---|
| `test_mapToPhoto_100` | PhotoResponseDTO → Photo 변환 100개 |
| `test_mapToPhoto_1000` | 1000개 |
| `test_fullPipeline_decodeAndMap_100` | JSON → DTO → Photo 전체 파이프라인 100개 |
| `test_filterNonSensitivePhotos_1000` | 비민감 사진 필터링 (#40 벤치마크 대상) |
| `test_filterSensitivePhotos_1000` | 민감 사진 필터링 (#40 벤치마크 대상) |
| `test_countSensitivePhotos_1000` | 민감 사진 카운트 (#40 벤치마크 대상) |

---

### `MemoryPerformanceTests.swift`

메모리 사용량 측정 전용 스위트 — `XCTMemoryMetric`을 유지하는 유일한 파일. baseline 비교 없이 측정값 확인 용도로 사용한다.

| 테스트 | 측정 대상 |
|---|---|
| `test_memoryFootprint_homeModels_1000` | Photo 1000개 메모리 사용량 |
| `test_memoryFootprint_searchResults_500` | SearchResults 500개 메모리 |
| `test_memoryPeak_fullPipeline_1000` | JSON→DTO→Model 파이프라인 메모리 피크 |

---

### `TokenPerformanceTests.swift`

| 테스트 | 측정 대상 |
|---|---|
| `test_tokenStore_save_1000` | Keychain 토큰 저장 1000회 |
| `test_tokenStore_read_1000` | Keychain 토큰 읽기 1000회 |
| `test_tokenStore_hasTokens_check_1000` | hasTokens 체크 1000회 |
| `test_tokenRefreshCycle_500` | 읽기→확인→저장 사이클 500회 |
| `test_tokenStore_clear_1000` | 토큰 삭제 1000회 |

---

### `PhotoInfoPerformanceTests.swift`

Step 7 Dictionary 기반 O(1) 태그 조회 전환 시 비교용 baseline.

| 테스트 | 측정 대상 |
|---|---|
| `test_optimisticTagUpdate_in10` | 배열 검색+교체 (10개 중) |
| `test_optimisticTagUpdate_in100` | 배열 검색+교체 (100개 중, 최악) |

---

### `HomeDerivedCollectionPerformanceTests.swift` (A/B 실측 · 19개 카운트에서 제외)

#40 관찰 성능 최적화의 근거 벤치마크. 파생 컬렉션 전략 A/B — 계산 프로퍼티(#47 이전,
접근마다 filter) vs didSet 캐싱(현재 HomeViewModel) — 를 body 평가 100회 × 사진 100/1000/10000으로 비교.
didSet 방식의 쓰기 비용(`photosAssign_10000`)도 함께 기록. 측정 수치는 `BASELINE_RESULTS.md` 참조.

| 테스트 | 측정 대상 |
|---|---|
| `test_computedProperty_bodyEval100_photos100/1000/10000` | 계산 프로퍼티: body 평가마다 filter 재실행 |
| `test_didSetCache_bodyEval100_photos100/1000/10000` | didSet 캐싱: 저장 프로퍼티 읽기 |
| `test_didSetCache_photosAssign_10000` | 트레이드오프: photos 교체 시 didSet 갱신 1회 |
| `test_didSetCache_bodyEval10000_photos100/1000/10000` | 위 B를 평가 10,000회로 — 타이머 분해능 보강용 |
| `test_computedProperty_bodyEval10000_photos1000` | 같은 평가 횟수의 A 대조군 (선형성 교차 검증) |

> **Release에서 B는 측정되지 않는다.** 저장 프로퍼티 읽기라 `-O` + wholemodule에서 루프 불변으로
> 판정되어 컴파일러가 반복을 제거한다. 평가 10,000회 테스트를 추가한 것도 이걸 증명하기 위함이다 —
> A는 반복 100배에 정확히 100.7배가 되는데 B는 2.7~5.5배에 그친다.
> B의 평가당 절대값은 인용하지 말 것. 근거는 `BASELINE_RESULTS.md`.

---

### `UploadMemoryBenchmark.swift` (측정 전용 · 19개 카운트에서 제외)

업로드 전처리(#34 ImageIO 다운샘플) 메모리 피크의 전/후 비교 측정. `XCTMemoryMetric` 대신
`task_vm_info.phys_footprint` 폴링으로 작업 구간의 피크 증가분(delta)을 잰다 — 프로세스 전체
피크에 셋업 메모리가 섞이는 오염을 피하기 위함. baseline 비교 없음, 결과는 콘솔 출력.

입력으로 카메라 원본 사진이 필요한데 개인 EXIF 때문에 커밋하지 않는다. `fixtureURL()`이
`Rephoto_iOSTests/Performance/Fixtures/`(테스트 번들 동봉 — 실기기용) → 리포 루트
`MockImagesReal/`(호스트 — 시뮬레이터용) 순으로 찾고, 둘 다 없으면 **자동 스킵**된다.
앱 타겟 `Resources/`에는 두지 말 것 — `MockImages`와 파일명이 겹쳐 번들 복사 충돌이 난다.
실기기 + Release 실행 절차는 [`TESTING.md`](TESTING.md), 측정 수치는 `BASELINE_RESULTS.md` 참조.

| 테스트 | 측정 대상 |
|---|---|
| `test_fullDecodeControl_peakDelta` | 풀디코드 대조군: UIImage 전체 디코드 + JPEG 재인코딩 (레거시 앱 재현 아님 — 라벨 정정 이력은 `BASELINE_RESULTS.md`) |
| `test_current_downsampleExtract_peakDelta` | 현재: `PhotoMetadataExtractor.extract` (2048px 썸네일 디코드) |

---

### `DecodeVariantBenchTests.swift` (측정 전용 · 19개 카운트에서 제외)

위 풀디코드 대조군의 +19MB가 어디서 온 값인지 가르는 대조 실험.
`UIImage` lazy decoding 때문에 디코드를 안 한 것인지, YUV 4:2:0으로 푼 것인지를
네 변형(`A_lazy` / `B_prepared` / `C_cgdraw` / `D_legacy_control`)을 같은 세션에서 찍어 비교한다.

입력과 `FootprintSampler`는 `UploadMemoryBenchmark`와 공유하므로 스킵 조건도 동일하다
(`MockImagesReal/` 없으면 자동 스킵). 목적·변형 정의·실행 명령은 [`TESTING.md`](TESTING.md),
결과 기록은 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)에 있다.

| 테스트 | 측정 대상 |
|---|---|
| `test_A_lazy_peakDelta` | `UIImage(data:)`만 — 디코드 강제 없음 |
| `test_B_prepared_peakDelta` | `preparingForDisplay()` — 플랫폼이 고른 픽셀 포맷 |
| `test_C_cgdraw_peakDelta` | RGBA 8bit `CGContext` draw — 강제 풀디코드 |
| `test_D_legacyControl_peakDelta` | 기존 풀디코드 대조군의 복사본 |

변형별 독립 메서드로 나뉜 이유, 집계를 `max`로 쓰는 이유는 [`TESTING.md`](TESTING.md)의
"측정 설계에서 반드시 지켜야 할 세 가지"에 있다. 순서 의존성을 없애려면 `-only-testing`으로
하나씩 실행한다.

---

## 벤치마크 → 후속 작업 매핑

| 테스트 파일 | 후속 작업 |
|---|---|
| `MappingPerformanceTests` (filterSensitive 계열) | #40 Home 파생 컬렉션 캐싱 벤치마크 |
| `PhotoInfoPerformanceTests` | Step 7 Dictionary 기반 태그 조회 |
| `DecodingPerformanceTests` | Step 7 캐시 기반 diff 업데이트 |
| `TokenPerformanceTests` | Keychain 성능 회귀 감시 |
| `MemoryPerformanceTests` | 대량 데이터 메모리 회귀 감시 |
