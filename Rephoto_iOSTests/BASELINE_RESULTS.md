# Rephoto iOS 성능 측정 결과 (레거시 baseline)

> 측정일: 2026-04-29
> 디바이스: iPhone 17 Pro Simulator (iPhone18,1)
> 호스트: Apple M4 (Mac16,12), macOS
> 각 테스트 5회 반복 측정, 평균값 기록
> 리팩토링 후 동일 테스트 실행 시 이 값과 비교됨

> **2026-07-23 스위트 정리**: 현재 스위트(19개, `TEST_GUIDE.md` 참조)에 남은 테스트의 기록만 유지한다.
> 삭제된 테스트(`DateFormatter`/`PhotoLoading`/`CacheHash`/`ImageCompression` 전체, 소규모·500급 티어 등)의 측정 기록은 git 히스토리의 이 파일 이전 버전에서 확인할 수 있다.
> Memory 메트릭 baseline은 신뢰성 문제(physical 0.0kB, peak는 프로세스 전체값)로 비교 대상에서 제외 — `MemoryPerformanceTests`는 baseline 없이 측정값 확인용으로만 유지.
> 남은 테스트의 새 baseline은 재기록 필요 (`Cmd + U` → Test Report → Set Baseline).

---

## DecodingPerformanceTests

### `test_decodePhotos_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000408** | s | 0.000400, 0.000413, 0.000409, 0.000408, 0.000409 |

### `test_decodePhotos_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.003610** | s | 0.003655, 0.004018, 0.003449, 0.003438, 0.003488 |

### `test_decodeSearchResponse_200()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000294** | s | 0.000307, 0.000297, 0.000305, 0.000297, 0.000262 |


## MappingPerformanceTests

### `test_mapToHomeModel_100()` (현 `test_mapToPhoto_100`의 전신)

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.005152** | s | 0.005052, 0.005083, 0.005199, 0.005217, 0.005206 |

### `test_mapToHomeModel_1000()` (현 `test_mapToPhoto_1000`의 전신)

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.054061** | s | 0.054532, 0.053229, 0.054181, 0.053546, 0.054816 |

### `test_fullPipeline_decodeAndMap_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.005101** | s | 0.005189, 0.005522, 0.004957, 0.004891, 0.004943 |

### `test_filterSensitivePhotos_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000387** | s | 0.000416, 0.000395, 0.000371, 0.000374, 0.000379 |

> `test_filterNonSensitivePhotos_1000`, `test_countSensitivePhotos_1000`은 레거시 시점 측정 기록 없음 — 재기록 시 신규 등록.


## MemoryPerformanceTests

> 재측정일: 2026-05-07 — 객체 retain 방식으로 수정 후 재측정 (이전 측정은 measure 블록 내 할당/해제로 Memory Physical이 항상 0.0이었음)
> baseline 비교 없이 측정값 확인용.

### `test_memoryFootprint_homeModels_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Memory Peak Physical | **39317.3** | kB | 39930.0, 39471.3, 39061.7, 39061.7, 39061.7 |
| Memory Physical | **-59.0** | kB | 81.9, -376.8, 0.0, -16.4, 16.4 |

### `test_memoryFootprint_searchResults_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Memory Peak Physical | **40913.1** | kB | 40913.1, 40913.1, 40913.1, 40913.1, 40913.1 |
| Memory Physical | **3.3** | kB | 16.4, 0.0, 0.0, 0.0, 0.0 |

### `test_memoryPeak_fullPipeline_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.065328** | s | 0.061985, 0.063404, 0.064062, 0.070460, 0.066730 |
| Memory Peak Physical | **41142.5** | kB | 41289.9, 41175.2, 41076.9, 41076.9, 41093.3 |
| Memory Physical | **19.7** | kB | 180.2, -98.3, 0.0, 0.0, 16.4 |


## PhotoInfoPerformanceTests

### `test_optimisticTagUpdate_in10()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000373** | s | 0.000376, 0.000370, 0.000370, 0.000357, 0.000390 |

### `test_optimisticTagUpdate_in100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.004721** | s | 0.004808, 0.004386, 0.004754, 0.005072, 0.004584 |


## TokenPerformanceTests

### `test_tokenRefreshCycle_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.300955** | s | 0.335950, 0.302193, 0.290585, 0.290684, 0.285362 |

### `test_tokenStore_clear_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **1.545915** | s | 1.429254, 1.516569, 1.557243, 1.568520, 1.657991 |

### `test_tokenStore_hasTokens_check_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000849** | s | 0.000854, 0.000848, 0.000872, 0.000840, 0.000829 |

### `test_tokenStore_read_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000902** | s | 0.000889, 0.000909, 0.000915, 0.000904, 0.000893 |

### `test_tokenStore_save_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.493205** | s | 0.438964, 0.495928, 0.555533, 0.539030, 0.436571 |

---

## UploadMemoryBenchmark (업로드 전처리 실측 — 2026-07-23)

> 입력: 아이폰 카메라 원본 IMG_9898.jpeg 4032×3024 (5,733KB) · iPhone 17 Pro Simulator
> 측정: `task_vm_info.phys_footprint` 0.2ms 폴링 — 작업 구간 피크 증가분(delta)

| 경로 | 메모리 피크 delta (5회) | 처리 시간 | 페이로드 |
|---|---|---|---|
| 레거시: UIImage 풀디코드 + 재인코딩 | +19.1, +19.1, +19.5, +19.3, +17.2 MB | ~0.25s | 5,733KB (원본 그대로 업로드) |
| 현재: ImageIO 다운샘플 2048px (`PhotoMetadataExtractor.extract`) | +171.1(워밍업), +49.1, +50.4, +50.4, +50.4 MB | ~0.17s | **1,547KB (−73%)** |

**발견**: "썸네일 API가 디코드 자체를 축소해 메모리 피크를 낮춘다"는 가설은 **기각**.
`CGImageSourceCreateThumbnailAtIndex`가 풀사이즈 RGBA(4032×3024×4 ≈ 47MB)를 디코드한 뒤 축소하는 반면
(`+50MB` delta가 정확히 그 크기), `UIImage(data:)` 디코드는 YUV 4:2:0(≈18MB)로 떨어져 오히려 가볍다.
이 최적화(#34)의 실증된 효과는 **페이로드 −73% + 처리 시간 −30%**이며, 메모리 개선 주장은 실측 근거 없음.
→ 아래 옵션 대조 실험에서 원인 규명 후 #49에서 수정.

### 다운샘플 옵션 대조 실험 (`test_downsampleOptions_experiment`, 2026-07-23)

가설 검증: Transform(EXIF 회전) vs maxPixelSize 경계, 무엇이 풀사이즈 디코드를 유발하는가.

| 변형 | 피크 delta (3회) | 시간 | 출력 |
|---|---|---|---|
| A 현행 — transform:true, max **2048** | +41.5, +50.3, +50.0 MB | 0.146s | 1536×2048 |
| B transform:false, max 2048 | +38.4 ×3 MB | 0.142s | 2048×1536 |
| C transform:false, max **2016** | +24.1 ×3 MB | 0.113s | 2016×1512 |
| D transform:true, max **2016** | +27.9~28.7 MB | 0.117s | 1512×2016 |

**결론**: 주범은 Transform(+4MB에 불과)이 아니라 **maxPixelSize 경계 미정렬**.
서브샘플(1/2ⁿ) 디코드는 `원본/2ⁿ ≥ maxPixelSize`일 때만 성립 — 4032 원본에 2048을 요청하면
1/2 디코드(2016)로는 목표를 못 채워 풀사이즈로 떨어진다. 2016으로 정렬하면 피크 절반, 시간 −20%.

**수정 및 재측정 (#49)**: `PhotoMetadataExtractor` 목표 크기를 원본 기반 동적 계산으로 변경
(긴 변을 2로 나눠가며 2048 이하가 되는 첫 값) → 프로덕션 경로(`extract`) 재측정
**+28.7MB / 0.12s** (수정 전 +50MB / 0.146s). 페이로드 1540KB로 동일, EXIF 회전 유지.

---

## HomeDerivedCollectionPerformanceTests (파생 컬렉션 전략 A/B — 2026-07-23, #40)

> 시나리오: body 평가 100회 × 사진 100/1000/10000 · iPhone 17 Pro Simulator · XCTClockMetric 5회 반복
> A = 계산 프로퍼티(#47 이전, 접근마다 filter 재실행) / B = didSet 캐싱(현재 HomeViewModel)

| 사진 수 | A. 계산 프로퍼티 | B. didSet 캐싱 | 비율 |
|---|---|---|---|
| 100 | 0.005032s | 0.000027s | ~186× |
| 1,000 | 0.042196s | 0.000025s | ~1,700× |
| 10,000 | 0.412262s | 0.000032s | ~12,900× |

**결론**: 계산 프로퍼티의 읽기 비용은 사진 수에 선형 비례 — 10,000장이면 body 100회에 0.41초로
스크롤 중 프레임 드랍 수준. didSet 캐싱은 규모와 무관하게 상수(~0.3µs/평가).
트레이드오프인 쓰기 비용(`photosAssign_10000`)은 10,000장 통째 교체당 **4.9ms 1회**로,
fetchPhotos() 빈도를 감안하면 읽기 절감 대비 무시 가능. → #47의 didSet 전환을 수치로 검증, #40 마감 근거.

---

## 요약

| 테스트 | Clock (s) | Memory Peak (kB) |
|---|---|---|
| `DecodingPerformanceTests/test_decodePhotos_100()` | 0.000408 | N/A |
| `DecodingPerformanceTests/test_decodePhotos_1000()` | 0.003610 | N/A |
| `DecodingPerformanceTests/test_decodeSearchResponse_200()` | 0.000294 | N/A |
| `MappingPerformanceTests/test_mapToHomeModel_100()` | 0.005152 | N/A |
| `MappingPerformanceTests/test_mapToHomeModel_1000()` | 0.054061 | N/A |
| `MappingPerformanceTests/test_fullPipeline_decodeAndMap_100()` | 0.005101 | N/A |
| `MappingPerformanceTests/test_filterSensitivePhotos_1000()` | 0.000387 | N/A |
| `MemoryPerformanceTests/test_memoryFootprint_homeModels_1000()` | N/A | 39317.3 |
| `MemoryPerformanceTests/test_memoryFootprint_searchResults_500()` | N/A | 40913.1 |
| `MemoryPerformanceTests/test_memoryPeak_fullPipeline_1000()` | 0.065328 | 41142.5 |
| `PhotoInfoPerformanceTests/test_optimisticTagUpdate_in10()` | 0.000373 | N/A |
| `PhotoInfoPerformanceTests/test_optimisticTagUpdate_in100()` | 0.004721 | N/A |
| `TokenPerformanceTests/test_tokenRefreshCycle_500()` | 0.300955 | N/A |
| `TokenPerformanceTests/test_tokenStore_clear_1000()` | 1.545915 | N/A |
| `TokenPerformanceTests/test_tokenStore_hasTokens_check_1000()` | 0.000849 | N/A |
| `TokenPerformanceTests/test_tokenStore_read_1000()` | 0.000902 | N/A |
| `TokenPerformanceTests/test_tokenStore_save_1000()` | 0.493205 | N/A |
