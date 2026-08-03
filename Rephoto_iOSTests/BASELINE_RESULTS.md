# Rephoto iOS 성능 측정 결과 (레거시 baseline)

> ⚠️ **측정 환경이 섹션마다 다르다. 표를 읽기 전에 각 섹션 머리의 환경 블록을 반드시 먼저 볼 것.**
>
> | 범위 | 환경 | 신뢰도 |
> |---|---|---|
> | 문서 앞부분의 레거시 baseline (`Decoding` / `Mapping` / `Memory` / `PhotoInfo` / `Token`)과 맨 아래 「요약」 표 | **시뮬레이터 + Debug** (`-Onone`) | 상대 비교용만 |
> | `UploadMemoryBenchmark`의 "실기기 + Release 재측정" 절부터 그 이후 전부 — A16/A13 교차 검증, `DecodeVariantBenchTests`, `HomeDerivedCollectionPerformanceTests` | **실기기 + Release** (`-O`) | 판정 근거로 사용 가능 |
>
> 시뮬레이터는 호스트 macOS의 코덱·메모리 서브시스템을 쓰고 Debug는 `-Onone`이라,
> 특히 **이미지 디코드 메모리**와 **연산 위주 Clock 수치**가 실기기와 실제로 갈린다
> (이 문서에서 두 번 확인됐다 — 대조군 19MB↔9.8MB, maxPixelSize 정렬 효과는 시뮬레이터에서만 재현).

## 측정 환경

새로 측정할 때마다 아래 필드를 채워 해당 섹션 머리에 붙인다. 비워두지 않는다 —
환경이 빠진 수치는 나중에 비교 대상이 되지 못한다.

```
> 측정일:            YYYY-MM-DD
> 기기 모델:          (예: iPhone 15 Pro / iPhone17,1) — 시뮬레이터면 "iPhone 17 Pro Simulator"로 명시
> iOS 버전:          (예: iOS 26.0) — 베타면 "26.0 beta"로 명시하고 빌드 번호를 함께 적는다
> 빌드 구성:          Debug | Release
> 최적화 수준:        -Onone | -O   (SWIFT_OPTIMIZATION_LEVEL)
> 테스트 플랜:        Rephoto_Performance
> 반복/집계:          N회 반복, 평균 | 중앙값 | max
>                     (피크 측정은 max를 쓴다 — 사유는 「집계를 max로 쓰는 이유」 절)
> 호스트(시뮬레이터만): (예: Apple M4 / Mac16,12, macOS 26)
```

### 베타 OS 단서

**2026-08-02·03 실기기 측정은 전부 iOS 27.0 beta (build 24A5380h)에서 수행됐다.**
베타 빌드는 정식 릴리스와 다음이 다를 수 있다.

- **디버그 계측 잔존** — 베타 OS는 어서션·로깅이 켜진 프레임워크를 포함하는 경우가 있어
  절대 시간이 정식 대비 부풀 수 있다.
- **디코더·메모리 동작 튜닝** — 이 문서의 핵심 발견(픽셀 포맷 선택, `phys_footprint` 회수 시점)이
  정확히 그 영역이다. 정식 릴리스에서 바뀌지 않는다는 보장이 없다.

**따라서 절대 수치보다 같은 세션 안의 비교(변형 간 비율, 이론값과의 일치)를 신뢰한다.**
실제로 이 문서가 결론으로 채택한 것들은 모두 그런 형태다 —
C_cgdraw가 이론값과 0.2% 일치, D가 출력 JPEG 크기와 일치, A/B의 반복 스케일링 배율.
빌드 번호까지 남기는 이유도 나중에 정식 릴리스에서 재측정해 대조하기 위함이다.

> 정식 iOS 27이 나오면 최소한 `DecodeVariantBenchTests` 4종과
> `test_downsampleOptions_experiment`는 다시 돌려 이 단서를 해소할 것.

### 현재 기록의 환경

> 측정일: 2026-04-29 (이후 섹션별 재측정일은 각 섹션에 명시)
> 기기 모델: iPhone 17 Pro Simulator (iPhone18,1)
> iOS 버전: 미기록 — 재측정 시 반드시 채울 것
> 빌드 구성: **Debug** / 최적화 `-Onone`
> 테스트 플랜: Rephoto_Performance
> 반복/집계: 각 테스트 5회 반복, 평균값 기록
> 호스트: Apple M4 (Mac16,12), macOS
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

> ⚠️ 시뮬레이터 + Debug 측정, 실기기 재측정 예정
> 입력: 아이폰 카메라 원본 IMG_9898.jpeg 4032×3024 (5,733KB) · iPhone 17 Pro Simulator
> 빌드 구성: Debug / `-Onone` · iOS 버전 미기록
> 측정: `task_vm_info.phys_footprint` 폴링(`usleep(200)` = 0.2ms 간격) — 작업 구간 피크 증가분(delta)

| 경로 | 메모리 피크 delta (5회) | 처리 시간 | 페이로드 |
|---|---|---|---|
| 다운샘플 없는 대조군: UIImage 전체 디코드 + 재인코딩 (`test_undownsampledReencode_peakDelta`) | +19.1, +19.1, +19.5, +19.3, +17.2 MB | ~0.25s | — (페이로드 비교 대상 아님) |
| 현재: ImageIO 다운샘플 2048px (`PhotoMetadataExtractor.extract`) | +171.1(워밍업), +49.1, +50.4, +50.4, +50.4 MB | ~0.17s | **1,547KB (레거시 앱 5,733KB 대비 −73%)** |

> **라벨 정정 (2026-08-02)**: 위 대조군은 종전에 "레거시"로 표기했으나, 리팩토링 전 앱의 재현이 아니다.
> 실제 레거시 앱(#34 이전 `PhotoMetadataExtractor`)은 픽셀을 디코드하지 않고 EXIF 속성만 읽은 뒤
> 원본 파일을 그대로 업로드했다 — 전처리 상주는 원본 Data(≈5.7MB) 수준, 페이로드 5,733KB.
> 대조군은 "다운샘플하지 않는 표준 구현(전체 디코드 + 재인코딩)"의 메모리 기준선으로 유효해 유지한다.
> 따라서 페이로드의 비교 기준은 레거시 앱 실측(5,733KB), 메모리 피크의 비교 기준은 현재 코드의 수정 전후(+50.4 → +28.7MB)다.

**발견**: "썸네일 API가 디코드 자체를 축소해 메모리 피크를 낮춘다"는 가설은 **기각**.
`CGImageSourceCreateThumbnailAtIndex`가 풀사이즈 RGBA(4032×3024×4 ≈ 46.5MB)를 디코드한 뒤 축소하는 반면
(`+50MB` delta가 정확히 그 크기), `UIImage(data:)` 디코드는 YUV 4:2:0(≈18MB)로 떨어져 오히려 가볍다.
이 최적화(#34+#49)의 실증된 효과는 **페이로드 −74% + 처리 시간 −22%(A16)·−24%(A13)**이며
(프로덕션 경로 A→D 기준 — 아래 「비교쌍 주의」 참조), 메모리 개선 주장은 실측 근거 없음.
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

### 실기기 + Release 재측정 (2026-08-02)

> 측정일: 2026-08-02
> 기기 모델: **iPhone 14 Pro (iPhone15,2)** — 실기기
> iOS 버전: **27.0 beta** (build 24A5380h) — 정식 릴리스 아님, 「측정 환경 > 베타 OS 단서」 참조
> 빌드 구성: **Release** / 최적화 `-O`
> 테스트 플랜: Rephoto_Performance · 반복: 표기대로
> 입력: 위와 동일 (IMG_9898.jpeg 4032×3024, 5,733KB)

| 테스트 | 실기기 Release | (참고) 시뮬레이터 Debug |
|---|---|---|
| `test_undownsampledReencode_peakDelta` | +9.8, 9.3, 9.8, 9.7, 8.7 MB · **0.146s** | +17.2~19.5MB · ~0.25s |
| `test_current_downsampleExtract_peakDelta` | +26.3(콜드), 19.5, 19.7, 19.7, 19.7 MB · **0.023s** | +28.7MB · 0.12s (#49 수정 후) |

**옵션 대조 실험 (`test_downsampleOptions_experiment`) — 실기기**

| 변형 | 피크 delta (3회) | 시간 | 출력 |
|---|---|---|---|
| A 현행 — transform:true, max 2048 | +37.8(콜드), 20.0, 20.0 MB | 0.027s | 1536×2048 1512KB |
| B transform:false, max 2048 | +20.0 ×3 MB | 0.027s | 2048×1536 1525KB |
| C transform:false, max **2016** | +1.7(콜드), 19.7, 19.7 MB | **0.019s** | 2016×1512 1472KB |
| D transform:true, max **2016** | +24.2(콜드), 19.7, 19.7 MB | 0.021s | 1512×2016 1466KB |

> ⚠️ **실기기에서는 maxPixelSize 미정렬로 인한 메모리 폭증이 재현되지 않는다.**
> 시뮬레이터에서는 2048 요청 시 +41~50MB, 2016 정렬 시 +24MB로 **두 배 차이**가 났지만,
> 실기기에서는 네 변형이 전부 **+19.7~20.0MB로 동일**하다. 서브샘플 디코드 경계 이야기는
> 시뮬레이터(호스트 macOS 소프트웨어 디코더)에서만 성립하고, 기기의 하드웨어 디코더는
> 목표 크기와 무관하게 같은 메모리로 처리한다.
>
> 따라서 **#49의 "메모리 피크 절반" 주장은 실기기 기준으로는 성립하지 않는다.**
> 다만 **처리 시간은 실기기에서도 2016 정렬이 빠르다.**
> 시간 개선은 유효하고 메모리 개선은 시뮬레이터 한정이었다는 것이 정확한 서술이다.
>
> **⚠️ 비교쌍 주의 (2026-08-03 정정)**: 종전 서술 "0.027s → 0.019s, −30%"는
> A(transform **true**, 2048)와 C(transform **false**, 2016)를 비교해 **두 변수를 동시에 바꾼 값**이었다.
> 회전 여부를 고정한 정직한 비교는 두 가지다.
>
> | 비교 | 대상 | A16 | 의미 |
> |---|---|---|---|
> | **프로덕션 before→after (#49)** | **A → D** (둘 다 transform:true) | 0.027s → **0.021s = −22%** | **앱이 실제로 얻은 개선** |
> | 정렬만의 효과 (회전 고정) | B → C (둘 다 transform:false) | 0.027s → 0.019s = −30% | 경계 정렬 단독 효과 |
>
> 프로덕션 경로는 `kCGImageSourceCreateThumbnailWithTransform: true`(EXIF 회전 반영,
> `PhotoMetadataExtractor.swift`의 `downsampledJPEG` 옵션 딕셔너리)이므로
> **#49의 개선폭으로 인용할 수 있는 값은 A→D = −22%**다.
> 포트폴리오·기술 문서에는 −22%를 쓰고, −30%는 "회전을 끄면"이라는 조건과 함께만 쓴다.
>
> **페이로드도 같은 기준으로 정리한다.** 레거시 앱은 원본을 그대로 올렸으므로 비교 기준은 5,733KB다.
> 프로덕션 경로(D)의 실기기 출력은 **1,466KB(A16) / 1,465KB(A13) = −74%**이고,
> 시뮬레이터 값 1,540KB로 계산하면 −73%다. **인용값은 −74%**로 통일하고, 절대값을 말할 때는
> 반드시 환경을 붙인다(1,547KB는 #49 이전 시뮬 값이므로 인용 금지).

### 2세대 교차 검증 — iPhone SE 2 / A13 (2026-08-03)

> 측정일: 2026-08-03
> 기기 모델: **iPhone SE 2 (iPhone12,8 · A13 Bionic, RAM 3GB)** — 실기기
> iOS 버전: **26.6** (build 23G71) — **정식 릴리스**
> 빌드 구성: **Release** / 최적화 `-O`
> 목적: A16에서 관찰한 "하드웨어 디코더는 목표 크기와 무관" 일반화가 세대를 건너 성립하는지

| 변형 | 피크 delta (3회) | 시간 | 출력 |
|---|---|---|---|
| A 현행 — transform:true, max 2048 | +37.8(콜드), 20.0, 20.0 MB | 0.033s | 1536×2048 1510KB |
| B transform:false, max 2048 | +20.0 ×3 MB | 0.031s | 2048×1536 1523KB |
| C transform:false, max **2016** | +1.7(콜드), 19.7, 19.7 MB | **0.023s** | 2016×1512 1472KB |
| D transform:true, max **2016** | +24.2(콜드), 19.7, 19.7 MB | 0.025s | 1512×2016 1465KB |

**A13에서도 네 변형이 전부 +19.7~20.0MB로 동일하다.** A16과 수치까지 일치한다.
→ "기기 하드웨어 디코더는 목표 크기와 무관하다"는 **두 세대(A13·A16)에서 재현**됐다.
서브샘플 경계 미정렬로 인한 메모리 폭증은 **시뮬레이터 한정 아티팩트**로 확정한다.

**처리 시간은 A13에서도 정렬이 빠르다.** 위 「비교쌍 주의」와 같은 기준으로 정리하면:

| 비교 | 대상 | A13 | A16 |
|---|---|---|---|
| **프로덕션 before→after (#49)** | **A → D** (둘 다 transform:true) | 0.033s → **0.025s = −24%** | 0.027s → **0.021s = −22%** |
| 정렬만의 효과 (회전 고정) | B → C (둘 다 transform:false) | 0.031s → 0.023s = −26% | 0.027s → 0.019s = −30% |

같은 기기 안의 비교라 칩 성능이 약분되므로, **프로덕션 개선폭 −22~24%는 A13·A16 두 세대에서
재현된 실효 개선**이다. 세대 무관하다고 일반화하려면 세대를 더 측정해야 한다.

---

## DecodeVariantBenchTests (디코드 변형 대조 — 2026-08-02, 실기기 Release)

> **목적**: 위 "다운샘플 없는 대조군"이 왜 이론값(4032×3024×4 ≈ 46.5MB)의 절반도 안 나오는가.
> 가설 (a) `UIImage` lazy decoding으로 애초에 디코드하지 않음,
> (b) 디코더가 서브샘플 YUV(1.5~2B/px)로 풂.

> 측정일: 2026-08-02
> 기기 모델: **iPhone 14 Pro (iPhone15,2)** — 실기기
> iOS 버전: **27.0 beta** (build 24A5380h) — 정식 릴리스 아님, 「측정 환경 > 베타 OS 단서」 참조
> 빌드 구성: **Release** / 최적화 `-O` (`SWIFT_COMPILATION_MODE = wholemodule`)
> 테스트 플랜: Rephoto_Performance
> 반복/집계: 변형당 5회, **max** (중앙값이 아님 — 아래 "집계를 max로 쓰는 이유")
> 실행: 변형별 독립 테스트 메서드를 `-only-testing`으로 **하나씩 별도 프로세스** 실행
> 입력: IMG_9898.jpeg 4032×3024 (5,733KB) — 12,192,768px, `UploadMemoryBenchmark`와 동일 픽스처

| 변형 | max | 2회차 이후 | B/px | 이론값 대비 |
|---|---|---|---|---|
| `A_lazy` — `UIImage(data:)`만 | **+0.2MB** | +0.0 | ~0 | 디코드 없음 ✔ |
| `B_prepared` — `preparingForDisplay()` | **+17.2MB** | +0.0 (캐시) | **1.48** | YUV 4:2:0 = 1.5B/px (18.3MB) — 6% 이내 |
| `C_cgdraw` — RGBA 8bit `CGContext` draw | +139.7 (콜드) / **+46.6** | +46.3~46.7 | **4.01** | RGBA 8888 = 4B/px (46.5MB) — **오차 0.2%** |
| `D_undownsampled` — 기존 대조군 복사본 | +15.2 (콜드) / **+9.8** | +9.8 | 0.84 | 어떤 픽셀 포맷과도 불일치 |

원본 `UploadMemoryBenchmark.test_undownsampledReencode_peakDelta`도 같은 세션에서
**+8.7~9.8MB**를 냈다. 서로 다른 코드 경로가 일치하므로 D 값은 신뢰할 수 있다.

### 2세대 교차 검증 — iPhone SE 2 / A13 · iOS 26.6 정식 (2026-08-03)

| 변형 | **A13 / iOS 26.6 정식** | A16 / iOS 27.0 beta | 이론값 |
|---|---|---|---|
| `A_lazy` | +0.0MB | +0.2MB | 디코드 없음 ✔ |
| `B_prepared` | **+17.2MB** | **+17.2MB** | YUV 4:2:0 = 18.3MB |
| `C_cgdraw` | +141.5(콜드) / **+93.1** | +139.7(콜드) / **+46.6** | RGBA 46.5MB (×2 / ×1) |
| `D_undownsampled` | +11.4(콜드) / **+19.1** | +15.2(콜드) / **+9.8** | — |

**두 기기에서 같은 것 (교란 요인과 무관하게 안전)**

- `B_prepared`가 **두 기기 모두 정확히 17.2MB**다. 디스플레이 경로의 픽셀 포맷 선택
  (YUV 4:2:0, 1.48B/px)은 세대를 건너 동일하다.
- `C_cgdraw`는 두 기기 모두 RGBA 이론값의 정수배로 떨어진다 — A13은 **93.1MB ≈ 46.5×2**
  (소스 CGImage + 목적지 컨텍스트 둘 다 상주), A16은 **46.6MB ≈ 46.5×1** (하나만 상주).
  값 자체는 다르지만 둘 다 이론값에 0.2% 이내로 맞으므로 **계측기가 두 기기에서 정상 작동함이
  확인**된다. positive control로서의 역할은 달성했다.

### ⚠️ 미해결: D의 9.8 ↔ 19.1MB 차이 — 칩 세대와 OS를 분리하지 못했다

`D_undownsampled`이 A13에서 **19.1MB**(1.64B/px, YUV 4:2:0의 18.3MB에 근접),
A16에서 **9.8MB**(출력 JPEG 크기와 일치)다. 해석하면 A13은 `jpegData()` 경로가 풀해상도
YUV 버퍼를 상주시키고, A16은 비트맵 없이 출력 버퍼만 든다는 뜻이 된다.

**그러나 이 차이의 원인을 특정할 수 없다.** 두 기기가 칩 세대(A13 vs A16)와
OS 버전(26.6 정식 vs 27.0 beta) **양쪽 모두 다르기 때문**이다. 교란 변수가 분리되지 않았다.

- `B_prepared`가 두 기기에서 동일하다는 점은 단서가 된다 — **디코드 포맷 선택은 안 바뀌었고**,
  달라진 것은 `jpegData()` 재인코딩이 중간 버퍼를 물고 있느냐뿐이다.
- 참고로 시뮬레이터 Debug의 D도 +19.1MB로 A13과 같았다. 포트폴리오에 쓰였던 "+19MB"는
  **폐기된 값이 아니라 A13에서 재현되는 값**이었다.

> **재측정 계획**: iPhone 14 Pro를 **정식 iOS 27**로 올린 뒤 `test_D_undownsampled_peakDelta`를
> 다시 돌린다. 9.8MB가 유지되면 칩 세대 차이, 19.1MB로 바뀌면 베타 OS 차이다.
> 그전까지 이 항목은 **결론 없음**으로 두고, 포트폴리오·문서에 어느 쪽으로도 서술하지 않는다.

### 판정: 가설 (a)와 (b) 둘 다 — 단 서로 다른 대상에 적용된다

**D(대조군)의 9.8MB는 픽셀 버퍼가 아니라 출력 JPEG이다.** 같은 원본을 quality 1.0으로
재인코딩하면 출력이 **9.72MB**인데(`sips -s formatOptions 100`으로 검산), D의 피크 delta
9.8MB와 사실상 일치한다. 즉 `UIImage(data:)` → `jpegData(1.0)` 경로는 **풀사이즈 비트맵을
한 번도 상주시키지 않고** 출력 버퍼만 들고 있다 → **가설 (a)**.

**반면 디스플레이 경로로 디코드를 강제하면(B) 1.48B/px** — YUV 4:2:0(1.5B/px)에 근접하고,
이 값은 **A13·A16 두 기기에서 동일**하다 → **가설 (b)**.

**그리고 C가 반증을 닫는다.** 픽셀 포맷을 RGBA로 못박으면 이론값과 정수배로 일치한다
(A16 46.6 ≈ ×1, A13 93.1 ≈ ×2). 디코더가 46.5MB를 못 만드는 게 아니라,
**대조군이 그걸 요구한 적이 없다.**

> **결론: 이 대조군은 풀디코드가 아니다.** 어느 기기에서도 풀사이즈 RGBA(46.5MB)가
> 일어나지 않는다. "다운샘플 없는 디코드+재인코딩 경로"일 뿐이다.
> 이 벤치를 "풀디코드 대비 −N%" 같은 메모리 개선 근거로 쓰면 안 된다.
> (#34+#49의 실증된 효과는 **페이로드 −74% + 처리 시간 −22%(A16)·−24%(A13)**이다 —
> 프로덕션 경로 A→D 기준. 「비교쌍 주의」 참조.)
>
> **개명 이력 (2026-08-03)**: 이 발견에 따라 테스트 이름을
> `test_fullDecodeControl_peakDelta` → **`test_undownsampledReencode_peakDelta`**,
> 디코드 변형의 `D_legacy_control` → **`D_undownsampled`**로 바꿨다.
> 이전 커밋·이슈에서 옛 이름을 보면 같은 테스트로 읽으면 된다.
>
> 다만 **그 메모리가 무엇으로 채워지는지는 기기/OS마다 다르다** — A16에서는 출력 JPEG(9.8MB),
> A13에서는 YUV 버퍼(19.1MB)로 보인다. 원인은 위 "미해결" 절 참조. 확정 전까지는
> "풀디코드가 아니다"까지만 주장하고, 그 안의 구성은 서술하지 않는다.

### 집계를 max로 쓰는 이유 (1차 측정에서 드러난 결함)

`phys_footprint`는 `free()` 직후 바로 내려가지 않고, 프레임워크가 디코드 결과를 내부 캐시에
들고 있기도 한다. 그래서 2회차부터는 보유·캐시된 페이지를 재사용해 delta가 **+0.0MB**로 찍힌다
(B가 정확히 그랬다: 17.2 → 0, 0, 0, 0). 이 0.0은 "메모리를 안 썼다"가 아니라 **"못 쟀다"**이므로
중앙값을 쓰면 유효 샘플이 통째로 버려진다. 피크 측정에서는 max가 맞다.

같은 이유로 워밍업은 **변형 자신이 아닌** 64px 썸네일 디코드로 한다. 변형 자신을 미리 돌리면
그 변형의 디코드 캐시가 채워져 이후 측정이 전부 0.0이 된다.

C의 콜드런 139.7MB는 소스 디코드 + 컨텍스트 + 코덱 스크래치가 겹친 값이라 대표값으로 쓰지 않는다.
정상 상태 46.6MB가 이론값과 맞는 쪽이다.

> **미해결**: B의 17.2MB가 YUV 4:2:0(18.3MB) 대비 6% 낮은 이유는 확인하지 않았다.
> baseline이 이미 소폭 상승한 상태였을 가능성이 있다. 포맷 판정에는 영향이 없다고 보고 넘어간다.

---

## HomeDerivedCollectionPerformanceTests (파생 컬렉션 전략 A/B — 2026-08-03 실기기 Release, #40)

> 측정일: 2026-08-03
> 기기 모델: **iPhone 14 Pro (iPhone15,2)** — 실기기
> iOS 버전: **27.0 beta** (build 24A5380h) — 정식 릴리스 아님, 「측정 환경 > 베타 OS 단서」 참조
> 빌드 구성: **Release** / 최적화 `-O` (`SWIFT_COMPILATION_MODE = wholemodule`)
> 테스트 플랜: Rephoto_Performance · XCTClockMetric 5회 반복, 평균
> 시나리오: body 평가 100회 × 사진 100/1,000/10,000
> A = 계산 프로퍼티(#47 이전, 접근마다 filter 재실행) / B = didSet 캐싱(현재 `HomeViewModel`)

### A. 계산 프로퍼티 — 읽기 비용

| 사진 수 | 100회 평가 총합 | **평가 1회당** | 60fps 프레임 예산(16.7ms) 대비 |
|---|---|---|---|
| 100 | 0.000420s | 4.20µs | 0.025% |
| 1,000 | 0.003574s | 35.7µs | **0.21%** |
| 10,000 | 0.034403s | 344µs | **2.06%** |

상대표준편차 0.70~1.11%로 매우 안정적이다. 사진 수 100 : 1,000 : 10,000에 대해
1 : 8.5 : 81.9 — **거의 완벽한 선형**.

쓰기 비용(`photosAssign_10000`, 10,000장 통째 교체 1회): **0.37ms** (RSD 8.6%).

### B. didSet 캐싱 — Release에서는 측정 불가

| 사진 수 | 100회 평가 | 10,000회 평가 | 선형이면 | **실측 배율** |
|---|---|---|---|---|
| A (1,000장) | 3,574µs | 359,701µs | 357,400µs | **100.7×** ✔ |
| B (100장) | 1.8µs | 8.0µs | 180µs | 4.4× ✗ |
| B (1,000장) | 1.2µs | 6.6µs | 120µs | 5.5× ✗ |
| B (10,000장) | 2.6µs | 7.0µs | 260µs | 2.7× ✗ |

**같은 하네스에서 A는 반복을 100배 늘리면 정확히 100.7배가 되는데 B만 2.7~5.5배다.**
10,000회 기준 B의 평가당 비용은 0.68ns — 약 3GHz에서 **2 클럭**이다. 클래스 프로퍼티 로드 2회 +
`Array.count` + ARC를 2클럭에 하는 것은 불가능하다.

원인: B의 `visiblePhotos`/`sensitiveCount`는 **저장 프로퍼티**라 루프 안에서 값이 변하지 않는다.
Release `-O` + wholemodule에서 컴파일러가 루프 불변으로 판정해 읽기를 루프 밖으로 끌어낸다
(loop-invariant code motion). A는 `filter`가 매번 배열을 새로 할당하므로 접히지 않는다.

> **따라서 B의 평가당 절대값은 이 하네스로 인용할 수 없다.** 100회 측정에서 보이던 1~3µs도
> 실제 작업이 아니라 `measure` 블록의 고정 오버헤드였다 (반복을 100배 올려보고서야 드러났다).
> 정직하게 쓸 수 있는 표현: **"Release에서 컴파일러가 반복 읽기를 제거할 만큼 저렴하며,
> 사진 수 100/1,000/10,000에서 일정하다."**
>
> 숫자가 꼭 필요하면 하네스를 바꿔야 한다 (`@inline(never)` 블랙홀로 소비, 또는 매 반복마다
> 옵티마이저가 통과 못 하는 불투명 배리어 삽입). 결론이 바뀌지 않으므로 지금은 하지 않았다.

### 결론

계산 프로퍼티의 읽기 비용은 사진 수에 **선형 비례**하고, didSet 캐싱은 **규모와 무관하게 상수**다.
이 결론은 시뮬레이터 Debug 측정과 동일하며 실기기 Release에서도 유지된다.

다만 **최적화가 실제로 필요해지는 규모는 1,000장이 아니라 10,000장부터**다.
1,000장에서 계산 프로퍼티는 프레임 예산의 0.21%로 사실상 무해하고, 10,000장에서 2.06%가 된다.
→ #47의 didSet 전환은 "지금 느려서" 한 것이 아니라 "선형이라 규모에서 터지는 것을 상수로 막은" 것이다.
트레이드오프인 쓰기 비용 0.37ms(교체 1회)는 `fetchPhotos()` 빈도를 감안하면 무시 가능하다.

> **폐기된 이전 기록 (시뮬레이터 + Debug, 2026-07-23)**: A 0.005032 / 0.042196 / 0.412262s,
> B 0.000027 / 0.000025 / 0.000032s, 배율 ~186× / ~1,700× / ~12,900×, 쓰기 4.9ms.
> B 값은 위 사유로 무효이고, A 값은 Debug `-Onone` 탓에 실기기 대비 7~12배 부풀려져 있었다.
> 특히 포트폴리오에 쓰였던 **"0.42ms → 2.5% 프레임 예산"은 시뮬레이터 Debug의 1,000장 값**으로,
> 실기기 Release 기준으로는 **0.036ms / 0.21%**다.

---

## 요약

> ⚠️ 아래 표는 **레거시 baseline(시뮬레이터 + Debug)** 만 모은 것이다. 실기기 Release 수치는 각 섹션 참조.

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
