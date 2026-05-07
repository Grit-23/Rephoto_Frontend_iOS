# Rephoto iOS 성능 측정 결과 (레거시 baseline)

> 측정일: 2026-04-29
> 디바이스: iPhone 17 Pro Simulator (iPhone18,1)
> 호스트: Apple M4 (Mac16,12), macOS
> 각 테스트 5회 반복 측정, 평균값 기록
> 리팩토링 후 동일 테스트 실행 시 이 값과 비교됨

---

## CacheHashPerformanceTests

### `test_fullReplace_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.059681** | s | 0.060618, 0.060550, 0.059095, 0.059880, 0.058261 |
| Memory Peak Physical | **49088.8** | kB | 49088.8, 49088.8, 49088.8, 49088.8, 49088.8 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_fullReplace_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.027675** | s | 0.026333, 0.028421, 0.027920, 0.027744, 0.027956 |
| Memory Peak Physical | **49108.4** | kB | 49105.2, 49121.5, 49105.2, 49105.2, 49105.2 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## DateFormatterPerformanceTests

### `test_dateFormatter_createEveryTime_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.054989** | s | 0.056846, 0.055679, 0.053877, 0.054126, 0.054418 |
| Memory Peak Physical | **49003.6** | kB | 48990.5, 49006.8, 49006.8, 49006.8, 49006.8 |
| Memory Physical | **3.3** | kB | 0.0, 16.4, 0.0, 0.0, 0.0 |


## DecodingPerformanceTests

### `test_decodeAlbumList_20()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000030** | s | 0.000034, 0.000034, 0.000028, 0.000027, 0.000026 |
| Memory Peak Physical | **48974.1** | kB | 48974.1, 48974.1, 48974.1, 48974.1, 48974.1 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_decodePhotos_10()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000042** | s | 0.000040, 0.000046, 0.000047, 0.000038, 0.000039 |
| Memory Peak Physical | **48993.7** | kB | 48990.5, 48990.5, 48990.5, 48990.5, 49006.8 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_decodePhotos_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000408** | s | 0.000400, 0.000413, 0.000409, 0.000408, 0.000409 |
| Memory Peak Physical | **49092.0** | kB | 49105.2, 49088.8, 49088.8, 49088.8, 49088.8 |
| Memory Physical | **-3.3** | kB | -16.4, 0.0, 0.0, 0.0, 0.0 |

### `test_decodePhotos_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.003610** | s | 0.003655, 0.004018, 0.003449, 0.003438, 0.003488 |
| Memory Peak Physical | **49144.5** | kB | 49154.3, 49121.5, 49137.9, 49154.3, 49154.3 |
| Memory Physical | **0.0** | kB | -32.8, 0.0, 16.4, 16.4, 0.0 |

### `test_decodePhotos_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.001857** | s | 0.001891, 0.001991, 0.001965, 0.001733, 0.001706 |
| Memory Peak Physical | **49105.2** | kB | 49105.2, 49105.2, 49105.2, 49105.2, 49105.2 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_decodeSearchResponse_200()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000294** | s | 0.000307, 0.000297, 0.000305, 0.000297, 0.000262 |
| Memory Peak Physical | **49101.9** | kB | 49088.8, 49105.2, 49105.2, 49105.2, 49105.2 |
| Memory Physical | **3.3** | kB | 0.0, 16.4, 0.0, 0.0, 0.0 |

### `test_decodeSearchResponse_50()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000070** | s | 0.000072, 0.000070, 0.000069, 0.000070, 0.000067 |
| Memory Peak Physical | **49072.4** | kB | 49072.4, 49072.4, 49072.4, 49072.4, 49072.4 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## ImageCompressionPerformanceTests

### `test_jpegCompression_quality100_4K()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **1.046277** | s | 1.039447, 1.049565, 1.029610, 1.068638, 1.044124 |
| Memory Peak Physical | **559536.0** | kB | 559516.3, 559549.1, 559532.7, 559549.1, 559532.7 |
| Memory Physical | **3.3** | kB | 0.0, 16.4, 0.0, 0.0, 0.0 |

### `test_noCompression_originalData_4K()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000005** | s | 0.000007, 0.000007, 0.000004, 0.000003, 0.000004 |
| Memory Peak Physical | **520915.6** | kB | 520915.6, 520915.6, 520915.6, 520915.6, 520915.6 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## MappingPerformanceTests

### `test_filterSensitivePhotos_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000387** | s | 0.000416, 0.000395, 0.000371, 0.000374, 0.000379 |

### `test_fullPipeline_decodeAndMap_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.005101** | s | 0.005189, 0.005522, 0.004957, 0.004891, 0.004943 |
| Memory Peak Physical | **49121.5** | kB | 49121.5, 49121.5, 49121.5, 49121.5, 49121.5 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_fullPipeline_decodeAndMap_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.027700** | s | 0.027798, 0.028438, 0.027324, 0.027332, 0.027607 |
| Memory Peak Physical | **49124.8** | kB | 49121.5, 49121.5, 49121.5, 49137.9, 49121.5 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_mapToHomeModel_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.005152** | s | 0.005052, 0.005083, 0.005199, 0.005217, 0.005206 |
| Memory Peak Physical | **49121.5** | kB | 49121.5, 49121.5, 49121.5, 49121.5, 49121.5 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_mapToHomeModel_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.054061** | s | 0.054532, 0.053229, 0.054181, 0.053546, 0.054816 |
| Memory Peak Physical | **49131.4** | kB | 49121.5, 49121.5, 49137.9, 49137.9, 49137.9 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_mapToHomeModel_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.027441** | s | 0.026825, 0.026912, 0.028056, 0.027310, 0.028099 |
| Memory Peak Physical | **49154.3** | kB | 49154.3, 49154.3, 49154.3, 49154.3, 49154.3 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## MemoryPerformanceTests

> 재측정일: 2026-05-07 — 객체 retain 방식으로 수정 후 재측정 (이전 측정은 measure 블록 내 할당/해제로 Memory Physical이 항상 0.0이었음)

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

### `test_decodeTags_10()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000020** | s | 0.000027, 0.000016, 0.000019, 0.000016, 0.000020 |

### `test_decodeTags_100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000123** | s | 0.000124, 0.000125, 0.000124, 0.000120, 0.000123 |

### `test_descriptionTrimming_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000224** | s | 0.000227, 0.000224, 0.000224, 0.000225, 0.000222 |

### `test_encodeTagRequest_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000815** | s | 0.000823, 0.000819, 0.000815, 0.000816, 0.000803 |

### `test_optimisticTagUpdate_in10()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000373** | s | 0.000376, 0.000370, 0.000370, 0.000357, 0.000390 |

### `test_optimisticTagUpdate_in100()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.004721** | s | 0.004808, 0.004386, 0.004754, 0.005072, 0.004584 |

### `test_tagAppend_1000()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000149** | s | 0.000145, 0.000149, 0.000149, 0.000152, 0.000149 |
| Memory Peak Physical | **49105.2** | kB | 49105.2, 49105.2, 49105.2, 49105.2, 49105.2 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## PhotoLoadingPerformanceTests

### `test_dataContentsOf_4K()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000179** | s | 0.000216, 0.000193, 0.000169, 0.000159, 0.000159 |
| Memory Peak Physical | **490860.7** | kB | 490850.9, 490850.9, 490867.3, 490867.3, 490867.3 |
| Memory Physical | **3.3** | kB | 16.4, 0.0, 0.0, 0.0, 0.0 |

### `test_fileCopy_10photos()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.002550** | s | 0.002364, 0.002495, 0.002697, 0.002274, 0.002921 |
| Memory Peak Physical | **808061.7** | kB | 808061.7, 808061.7, 808061.7, 808061.7, 808061.7 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_loadAndParseEXIF_10photos()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.002938** | s | 0.002559, 0.002700, 0.002791, 0.002548, 0.004090 |
| Memory Peak Physical | **4368225.5** | kB | 4368225.5, 4368225.5, 4368225.5, 4368225.5, 4368225.5 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |

### `test_sequentialLoad_10photos()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.000684** | s | 0.000757, 0.000660, 0.000660, 0.000681, 0.000662 |
| Memory Peak Physical | **793119.5** | kB | 793119.5, 793119.5, 793119.5, 793119.5, 793119.5 |
| Memory Physical | **0.0** | kB | 0.0, 0.0, 0.0, 0.0, 0.0 |


## TokenPerformanceTests

### `test_tokenRefreshCycle_500()`

| Metric | 평균 | 단위 | 측정값 (5회) |
|---|---|---|---|
| Clock Monotonic Time | **0.300955** | s | 0.335950, 0.302193, 0.290585, 0.290684, 0.285362 |
| Memory Peak Physical | **49799.8** | kB | 49727.7, 49826.0, 49826.0, 49809.7, 49809.7 |
| Memory Physical | **131.1** | kB | 557.1, 114.7, -16.4, 0.0, 0.0 |

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

| 테스트 | Clock (s) | Memory (kB) |
|---|---|---|
| `CacheHashPerformanceTests/test_fullReplace_1000()` | 0.059681 | 0.0 |
| `CacheHashPerformanceTests/test_fullReplace_500()` | 0.027675 | 0.0 |
| `DateFormatterPerformanceTests/test_dateFormatter_createEveryTime_1000()` | 0.054989 | 3.3 |
| `DecodingPerformanceTests/test_decodeAlbumList_20()` | 0.000030 | 0.0 |
| `DecodingPerformanceTests/test_decodePhotos_10()` | 0.000042 | 0.0 |
| `DecodingPerformanceTests/test_decodePhotos_100()` | 0.000408 | -3.3 |
| `DecodingPerformanceTests/test_decodePhotos_1000()` | 0.003610 | 0.0 |
| `DecodingPerformanceTests/test_decodePhotos_500()` | 0.001857 | 0.0 |
| `DecodingPerformanceTests/test_decodeSearchResponse_200()` | 0.000294 | 3.3 |
| `DecodingPerformanceTests/test_decodeSearchResponse_50()` | 0.000070 | 0.0 |
| `ImageCompressionPerformanceTests/test_jpegCompression_quality100_4K()` | 1.046277 | 3.3 |
| `ImageCompressionPerformanceTests/test_noCompression_originalData_4K()` | 0.000005 | 0.0 |
| `MappingPerformanceTests/test_filterSensitivePhotos_1000()` | 0.000387 | N/A |
| `MappingPerformanceTests/test_fullPipeline_decodeAndMap_100()` | 0.005101 | 0.0 |
| `MappingPerformanceTests/test_fullPipeline_decodeAndMap_500()` | 0.027700 | 0.0 |
| `MappingPerformanceTests/test_mapToHomeModel_100()` | 0.005152 | 0.0 |
| `MappingPerformanceTests/test_mapToHomeModel_1000()` | 0.054061 | 0.0 |
| `MappingPerformanceTests/test_mapToHomeModel_500()` | 0.027441 | 0.0 |
| `MemoryPerformanceTests/test_memoryFootprint_homeModels_1000()` | N/A | Peak: 39317.3 |
| `MemoryPerformanceTests/test_memoryFootprint_searchResults_500()` | N/A | Peak: 40913.1 |
| `MemoryPerformanceTests/test_memoryPeak_fullPipeline_1000()` | 0.065328 | Peak: 41142.5 |
| `PhotoInfoPerformanceTests/test_decodeTags_10()` | 0.000020 | N/A |
| `PhotoInfoPerformanceTests/test_decodeTags_100()` | 0.000123 | N/A |
| `PhotoInfoPerformanceTests/test_descriptionTrimming_1000()` | 0.000224 | N/A |
| `PhotoInfoPerformanceTests/test_encodeTagRequest_1000()` | 0.000815 | N/A |
| `PhotoInfoPerformanceTests/test_optimisticTagUpdate_in10()` | 0.000373 | N/A |
| `PhotoInfoPerformanceTests/test_optimisticTagUpdate_in100()` | 0.004721 | N/A |
| `PhotoInfoPerformanceTests/test_tagAppend_1000()` | 0.000149 | 0.0 |
| `PhotoLoadingPerformanceTests/test_dataContentsOf_4K()` | 0.000179 | 3.3 |
| `PhotoLoadingPerformanceTests/test_fileCopy_10photos()` | 0.002550 | 0.0 |
| `PhotoLoadingPerformanceTests/test_loadAndParseEXIF_10photos()` | 0.002938 | 0.0 |
| `PhotoLoadingPerformanceTests/test_sequentialLoad_10photos()` | 0.000684 | 0.0 |
| `TokenPerformanceTests/test_tokenRefreshCycle_500()` | 0.300955 | 131.1 |
| `TokenPerformanceTests/test_tokenStore_clear_1000()` | 1.545915 | N/A |
| `TokenPerformanceTests/test_tokenStore_hasTokens_check_1000()` | 0.000849 | N/A |
| `TokenPerformanceTests/test_tokenStore_read_1000()` | 0.000902 | N/A |
| `TokenPerformanceTests/test_tokenStore_save_1000()` | 0.493205 | N/A |