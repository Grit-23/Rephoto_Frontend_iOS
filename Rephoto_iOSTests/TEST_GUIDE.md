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

## 벤치마크 → 후속 작업 매핑

| 테스트 파일 | 후속 작업 |
|---|---|
| `MappingPerformanceTests` (filterSensitive 계열) | #40 Home 파생 컬렉션 캐싱 벤치마크 |
| `PhotoInfoPerformanceTests` | Step 7 Dictionary 기반 태그 조회 |
| `DecodingPerformanceTests` | Step 7 캐시 기반 diff 업데이트 |
| `TokenPerformanceTests` | Keychain 성능 회귀 감시 |
| `MemoryPerformanceTests` | 대량 데이터 메모리 회귀 감시 |
