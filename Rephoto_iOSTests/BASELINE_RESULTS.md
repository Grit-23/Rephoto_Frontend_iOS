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
