# Rephoto iOS 성능 벤치마크 테스트 가이드

리팩토링 전 **현재 레거시 코드의 성능 baseline**을 측정하고, 리팩토링 후 동일한 테스트를 실행해서 비교하기 위한 테스트.

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

## 테스트 파일 구성 (39개 테스트)

### `MockDataFactory.swift`
공용 Mock 데이터 생성 팩토리.

---

### `DateFormatterPerformanceTests.swift`
**리팩토링 항목: #3 사진 관리**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_dateFormatter_createEveryTime_1000` | toHomeModel()에서 매번 DateFormatter 새로 생성 |

---

### `DecodingPerformanceTests.swift`
**리팩토링 항목: #3 사진 관리**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_decodePhotos_10` | 서버 응답 JSON → PhotoResponseDto 디코딩 10개 |
| `test_decodePhotos_100` | 100개 |
| `test_decodePhotos_500` | 500개 |
| `test_decodePhotos_1000` | 1000개 (스트레스) |
| `test_decodeSearchResponse_50` | 검색 결과 50개 |
| `test_decodeSearchResponse_200` | 검색 결과 200개 |
| `test_decodeAlbumList_20` | 앨범 리스트 20개 |

---

### `MappingPerformanceTests.swift`
**리팩토링 항목: #3 사진 관리**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_mapToHomeModel_100` | PhotoResponseDto → HomeModel 변환 100개 |
| `test_mapToHomeModel_500` | 500개 |
| `test_mapToHomeModel_1000` | 1000개 |
| `test_fullPipeline_decodeAndMap_100` | JSON → DTO → HomeModel 전체 파이프라인 100개 |
| `test_fullPipeline_decodeAndMap_500` | 500개 |
| `test_filterNonSensitivePhotos_1000` | 비민감 사진 필터링 |
| `test_filterSensitivePhotos_1000` | 민감 사진 필터링 |
| `test_countSensitivePhotos_1000` | 민감 사진 카운트 |

---

### `MemoryPerformanceTests.swift`
**리팩토링 항목: #3, #4**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_memoryFootprint_homeModels_1000` | HomeModel 1000개 메모리 사용량 |
| `test_memoryFootprint_searchResults_500` | SearchResults 500개 메모리 |
| `test_memoryPeak_fullPipeline_1000` | JSON→DTO→Model 파이프라인 메모리 피크 |

---

### `TokenPerformanceTests.swift`
**리팩토링 항목: #2 Token 관리 로직**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_tokenStore_save_1000` | UserDefaults 토큰 저장 1000회 |
| `test_tokenStore_read_1000` | UserDefaults 토큰 읽기 1000회 |
| `test_tokenStore_hasTokens_check_1000` | hasTokens 체크 1000회 |
| `test_tokenRefreshCycle_500` | 읽기→확인→저장 사이클 500회 |
| `test_tokenStore_clear_1000` | 토큰 삭제 1000회 |

---

### `PhotoLoadingPerformanceTests.swift`
**리팩토링 항목: #4 사진 로딩 비동기 처리**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_dataContentsOf_4K` | Data(contentsOf:) 동기 로딩 4K 1장 |
| `test_sequentialLoad_10photos` | for loop 순차 로딩 10장 |
| `test_fileCopy_10photos` | FileManager.copyItem 10장 |
| `test_loadAndParseEXIF_10photos` | 파일 읽기 → EXIF 파싱 10장 순차 |

---

### `CacheHashPerformanceTests.swift`
**리팩토링 항목: #5 캐시 기반 API 호출 최적화**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_fullReplace_500` | 매번 전체 목록 디코딩+매핑+배열 교체 500개 |
| `test_fullReplace_1000` | 1000개 |

---

### `Performance/ImageCompressionPerformanceTests.swift`
**리팩토링 항목: #3 사진 관리**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_noCompression_originalData_4K` | 원본 Data 그대로 업로드 |
| `test_jpegCompression_quality100_4K` | JPEG quality 1.0 변환 비용 |

---

### `PhotoInfoPerformanceTests.swift`
**리팩토링 항목: #6 사진 정보 수정**

| 테스트 | 현재 코드 동작 |
|---|---|
| `test_decodeTags_10` | 태그 10개 디코딩 |
| `test_decodeTags_100` | 태그 100개 디코딩 |
| `test_encodeTagRequest_1000` | 태그 요청 인코딩 1000회 |
| `test_optimisticTagUpdate_in10` | 배열 검색+교체 (10개 중) |
| `test_optimisticTagUpdate_in100` | 배열 검색+교체 (100개 중, 최악) |
| `test_tagAppend_1000` | 태그 append 1000회 |
| `test_descriptionTrimming_1000` | 설명 텍스트 trim 1000회 |

---

## 리팩토링 항목 → 테스트 매핑

| # | 항목 | 테스트 파일 |
|---|---|---|
| 2 | Token 관리 로직 | `TokenPerformanceTests` |
| 3 | 사진 관리 | `DateFormatter` + `Decoding` + `Mapping` + `ImageCompression` |
| 4 | 사진 로딩 비동기 | `PhotoLoading` + `Memory` |
| 5 | 캐시/API 호출 최적화 | `CacheHash` |
| 6 | 사진 정보 수정 | `PhotoInfo` |
