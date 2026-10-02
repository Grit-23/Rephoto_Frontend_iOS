# 실기기 재측정 — iPhone 14 Pro · iOS 27.2 developer beta (2026-10-02)

`BASELINE_RESULTS.md`의 실기기 수치(업로드 전처리 · 디코드 변형 · 파생 컬렉션)를 원본 로그와 함께 다시 잰 기록이다.
이전 측정(2026-08-02·03)은 콘솔 원문이 남아 있지 않아 이번에는 **회차별 원문을 이 폴더에 보존**한다.

## 인용할 값

| | 사진 1 (`IMG_9898`) | 사진 2 (`IMG_1568`, HEIC 촬영 → 피커 JPEG) | 인용 |
|---|---|---|---|
| 페이로드 | 5,733KB → 1,466KB, −74.4% | 2,317KB → 644KB, −72.2% | **−72–74%** |
| 다운샘플·인코딩 시간 (정렬 전 → 후) | 27.3 → 21.2ms, 약 −22% | 22.3 → 16.4ms, 약 −26% | **약 −22–26%** |

두 사진 모두 앱 경로(JPEG 디코드)이고, 회차별 편차는 ±1–2ms다.

## 측정 환경

```
측정일:        2026-10-02
기기 모델:      iPhone 14 Pro (iPhone15,2 · A16) — 실기기
iOS 버전:      27.2 developer beta (build 24B5089g) — 정식 릴리스 아님
Xcode:         27.1 (27A9269)
빌드 구성:      Release / -O, SWIFT_COMPILATION_MODE = wholemodule
               ENABLE_TESTABILITY=YES (커맨드라인 오버라이드 — TESTING.md 절차)
테스트 플랜:    Rephoto_Performance, -only-testing으로 테스트 1개씩 별도 프로세스 실행
반복/집계:      test_downsampleOptions_experiment — 프로세스 5회 × 변형당 3회 = 변형당 15샘플
               test_current_downsampleExtract_peakDelta — 프로세스 3회 × 5회 = 15샘플
               시간은 평균(분해능 1ms, 로그 %.3f초). "워밍"은 각 프로세스의 1회차를 뺀 값
               DecodeVariantBenchTests 4개 · HomeDerivedCollectionPerformanceTests 11개 — 각 프로세스 3회 × 5회
```

## 입력

| 포맷 | 파일 | 해상도 | 크기 | 촬영 |
|---|---|---|---|---|
| JPEG | `IMG_9898.jpeg` | 4032×3024 | 5,871,533 B (5,733KB) | iPhone 14 Pro · iOS 26.4 · 2026-04-02 |
| HEIC | `IMG_1568.HEIC` | 4032×3024 | 1,573,179 B (1,536KB) | iPhone 14 Pro · iOS 27.2 · 2026-10-02, 카메라 포맷 "고효율" |
| 피커 변환 JPEG | `IMG_1568_picker.jpg` | 4032×3024 | 2,372,869 B (2,317KB) | 위 HEIC를 앱의 PhotosPicker가 넘긴 데이터 그대로 |

`IMG_9898`과 `IMG_1568`은 **다른 장면**이다. 압축률은 사진 내용에 따라 달라지므로 두 사진의 비율을 직접 비교하지 않는다.
사진 파일은 개인 사진(GPS 포함)이라 커밋하지 않는다(`.gitignore`).

`IMG_9898.jpeg`의 헤더(JFIF 1.01 · 300dpi · Apple MPF)는 피커 변환본과 구조가 같다.
카메라가 직접 저장한 JPEG가 아니라 HEIC에서 시스템이 변환한 파일일 가능성이 있다(확정 아님).

## 결과 — JPEG 입력

### 처리 시간 (`test_downsampleOptions_experiment`)

| 변형 | 옵션 | 워밍 평균 (n=10) | 전체 평균 (n=15) | 범위 | 출력 |
|---|---|---|---|---|---|
| A | 회전 반영, max 2048 (#49 이전 앱) | 27.3ms | 27.5ms | 27–29ms | 1536×2048 · 1,512KB |
| B | 회전 안 함, max 2048 | 27.0ms | 27.0ms | 26–28ms | 2048×1536 · 1,525KB |
| C | 회전 안 함, max 2016 | 19.2ms | 19.4ms | 19–21ms | 2016×1512 · 1,472KB |
| D | 회전 반영, max 2016 (현재 앱) | 21.2ms | 21.2ms | 21–22ms | 1512×2016 · 1,466KB |

- **A → D (앱의 #49 전후): −22.3%** (워밍) / −23.0% (전체)
- B → C (회전 끈 상태에서 정렬만): −28.9% / −28.1%
- 2026-08-02(iOS 27.0 beta) 기록 A 0.027s → D 0.021s가 그대로 재현됐다.

### 실제 `extract()` 경로 (`test_current_downsampleExtract_peakDelta`)

- 처리 시간: 워밍 평균 **23.8ms** (n=12), 1회차 37–47ms. EXIF 파싱과 임시 파일 쓰기 포함
- 출력 파일: 기기에서 직접 가져옴(`extract_output_jpeg.jpg`) — **1,502,113 B (1,466KB) · 1512×2016**
- 페이로드: 5,871,533 B → 1,502,113 B = **−74.4%** (#34 이전 앱은 받은 사진을 그대로 업로드)

## 결과 — HEIC 입력 (참고: 앱 경로 아님)

HEIC 파일을 `extract()`에 직접 넣은 결과다. 아래 「앱이 실제로 받는 포맷」에서 확인했듯
이번 확인에서는 앱이 HEIC를 받지 않았으므로 인용하지 않는다.

### 처리 시간

| 변형 | 워밍 평균 (n=10) | 전체 평균 (n=15) | 범위 | 출력 |
|---|---|---|---|---|
| A (#49 이전 앱) | 63.3ms | 58.3ms | 42–86ms | 1536×2048 · 694KB |
| B | 53.7ms | 55.5ms | 45–70ms | 2048×1536 · 709KB |
| C | 53.9ms | 55.6ms | 42–79ms | 2016×1512 · 701KB |
| D (현재 앱) | 50.3ms | 52.6ms | 43–90ms | 1512×2016 · 699KB |

- A → D: −20.5% (워밍) / −9.7% (전체) — **집계 방식에 따라 두 배 차이**
- B → C: +0.4% / +0.2% — 정렬 효과 없음
- 회차별 편차(42–90ms)가 변형 간 차이보다 크다. **HEIC에서는 경계 정렬의 시간 효과를 확인하지 못했다.**
  1/2ⁿ 축소 디코드는 JPEG(8×8 DCT)의 특성이라 HEIC에서 같은 효과를 기대할 근거도 없다.

### 실제 `extract()` 경로

- 처리 시간: 워밍 평균 **48.6ms** (n=12), 1회차 79–85ms — JPEG 입력의 약 2배
- 출력 파일: `heic/extract_output_from_heic.jpg` — **716,409 B (699KB) · 1512×2016 · JPEG**
- 페이로드: 1,573,179 B → 716,409 B = **−54.5%**

## 앱이 실제로 받는 포맷 (PhotosPicker)

**이번 확인에서는 HEIC로 찍은 사진도 앱에 JPEG로 들어왔다.**

- 방법: DEBUG 앱에서 업로드로 `IMG_1568`(HEIC)을 선택. DEBUG의 `MockExtractPhotoMetadataUseCase`는
  피커가 넘긴 `Data`를 그대로 `tmp/<UUID>.jpg`에 쓴다 → `devicectl`로 가져와 확인 (`heic/picker_delivered_data.bin`)
- 결과: **JPEG**(JFIF, baseline) · 4032×3024 · **2,372,869 B** · 촬영 시각(18:58:37)·GPS·EXIF 유지
- 원인: `PhotosPicker`의 인코딩 정책이 기본값(`.automatic`)이고 `loadTransferable(type: Data.self)`로 받는다
  (`HomeView.swift`, `HomeViewModel.handlePickedPhotos`). 이번 기기·OS에서는 시스템이 JPEG로 변환해 넘겼다.
  정책 문서상 변환 여부는 시스템이 정하므로, 이 결과는 이 기기·OS 기준이다

따라서 **이번 확인(HEIC 사진 1장, iOS 27.2 beta)에서 앱이 디코드한 것은 JPEG**이고, 위 「HEIC 입력」 결과는 앱 경로가 아니라
"HEIC를 직접 받는다면"의 참고값이다. 앱 경로의 HEIC 촬영본 결과는 아래 「피커 변환 JPEG 입력」이다.

## 결과 — 피커 변환 JPEG 입력 (HEIC 촬영본의 실제 앱 경로)

### 처리 시간

| 변형 | 워밍 평균 (n=10) | 전체 평균 (n=15) | 범위 | 출력 |
|---|---|---|---|---|
| A (#49 이전 앱) | 22.3ms | 22.5ms | 22–23ms | 1536×2048 · 690KB |
| B | 22.6ms | 22.5ms | 21–24ms | 2048×1536 · 698KB |
| C | 14.5ms | 14.8ms | 14–17ms | 2016×1512 · 649KB |
| D (현재 앱) | 16.4ms | 16.4ms | 16–17ms | 1512×2016 · 644KB |

- **A → D: −26.5%** (워밍) / −27.2% (전체)
- B → C: −35.8% / −34.3%

### 실제 `extract()` 경로

- 처리 시간: 워밍 평균 **18.8ms** (n=12), 1회차 31–43ms
- 출력 파일: `picker_jpeg/extract_output_from_picker_jpeg.jpg` — **659,802 B (644KB) · 1512×2016**
- 페이로드: 2,372,869 B → 659,802 B = **−72.2%** (#34 이전 앱은 피커가 넘긴 데이터를 그대로 업로드)

## 참고 — 메모리 (인용하지 않음)

워밍 값 JPEG +19.7–20.3MB, HEIC +13.5–14.3MB. 네 변형을 한 프로세스에서 이어 돌리는 구조라
변형 간 메모리 비교 근거로 쓰지 않는다(순서 의존성 — `TESTING.md` 「측정 설계에서 반드시 지켜야 할 세 가지」 ③).

다만 JPEG 메모리 값은 2026-08-02 기록과 콜드 런까지 거의 같게 나왔다
(A 1회차 +37.8MB — 5프로세스 중 1번만 +38.0MB, C 1회차 +1.7MB, D 1회차 +24.2MB, 워밍 +19.7MB).
같은 입력이면 메모리 delta가 결정적으로 나오는 것으로 보인다.

## 결과 — 디코드 변형 (`DecodeVariantBenchTests`, `decode_variants/`)

입력 `IMG_9898.jpeg`. 변형당 프로세스 3회 × 5회. 대표값은 2회차 이후 값, B만 1회차 값이다(`BASELINE_RESULTS.md` 「집계 규칙」).

| 변형 | 프로세스별 로그 max (5회 중 최댓값) | 2회차 이후 | 이론값 |
|---|---|---|---|
| `A_lazy` | +0.0 / +0.0 / +0.0MB | +0.0 | 디코드 없음 |
| `B_prepared` | +17.2 / +17.3 / +17.2MB | +0.0–0.3 (캐시) | YUV 4:2:0 17.4MB |
| `C_cgdraw` | +139.6 ×3 (콜드) | +46.6 | RGBA 46.5MB |
| `D_undownsampled` | +14.0 / +14.6 / +14.8 (콜드) | +9.7–9.8 | 출력 JPEG(q1.0) 9.72MiB |

2026-08-02(iOS 27.0 beta) 기록과 콜드 런을 빼면 같다.

## 결과 — 파생 컬렉션 (`HomeDerivedCollectionPerformanceTests`, `home_derived/`)

XCTClockMetric, 테스트당 프로세스 3회 × 5회 = 15샘플 평균.

| 테스트 | 평균 | 범위 | RSD |
|---|---|---|---|
| `computedProperty_bodyEval100_photos100` | 397.7µs | 389–407 | 1.40% |
| `computedProperty_bodyEval100_photos1000` | 3,416.5µs | 3,404–3,428 | 0.25% |
| `computedProperty_bodyEval100_photos10000` | 32,882.7µs | 32,458–33,872 | 1.45% |
| `computedProperty_bodyEval10000_photos1000` | 362,973.7µs | 356,582–367,568 | 0.97% |
| `didSetCache_bodyEval100_photos100` | 2.2µs | 1–4 | 30.7% |
| `didSetCache_bodyEval100_photos1000` | 2.6µs | 2–6 | 45.5% |
| `didSetCache_bodyEval100_photos10000` | 2.3µs | 1–4 | 35.2% |
| `didSetCache_bodyEval10000_photos100` | 6.9µs | 6–8 | 10.8% |
| `didSetCache_bodyEval10000_photos1000` | 6.9µs | 6–8 | 8.6% |
| `didSetCache_bodyEval10000_photos10000` | 7.1µs | 6–8 | 10.0% |
| `didSetCache_photosAssign_10000` | 367.2µs | 336–432 | 9.4% |

- 계산 프로퍼티 평가 1회당: 3.98 / 34.2 / 329µs → 프레임 예산 60Hz(16.7ms) 대비 **0.024% / 0.20% / 1.97%**, 120Hz(8.33ms) 대비 0.048% / 0.41% / 3.95%
- 반복 100배 시 A는 106배, B는 2.7–3.1배 — B는 컴파일러가 읽기를 루프 밖으로 빼낸 것으로 보여(디스어셈블 미확인) 절대값 인용 불가
- 2026-08-03 기록(4.20 / 35.7 / 344µs)보다 4–5% 낮다. 결론은 같다

## 직접 확인하는 법

- **회차별 원문**: `options_run1~5.log`, `extract_run1~3.log` (HEIC는 `heic/`, 피커 변환 JPEG는 `picker_jpeg/` 아래 같은 이름),
  `decode_variants/<변형>_run1~3.log`, `home_derived/<테스트>_run1~3.log`.
  로그는 측정 줄만 남기도록 `grep`으로 거르고, 로컬 경로·기기 UDID가 든 줄은 지웠다(측정값 줄은 원문 그대로)
- **Xcode 결과 번들** (로컬 전용, `.gitignore`): 같은 이름의 `.xcresult`를 더블클릭 → Report 내비게이터에서 테스트 선택 → 콘솔 출력
- **출력 파일** (로컬 전용, `.gitignore`): `extract_output_jpeg.jpg`, `heic/extract_output_from_heic.jpg`,
  `picker_jpeg/extract_output_from_picker_jpeg.jpg`. Finder 정보 가져오기로 바이트 수 확인
- **피커가 넘긴 데이터** (로컬 전용, `.gitignore` — GPS 포함): `heic/picker_delivered_data.bin` — 확장자만 .bin이고 내용은 JPEG다. `.jpg`로 바꾸면 열린다
- **재계산**: 로그의 `run` 줄에서 시간 열만 모아 평균을 내면 위 표와 같다
- **변형 라벨**: 로그의 `A 현행`은 측정 당시 테스트 라벨이다. 지금 테스트 코드에서는 `A #49 이전`으로 바뀌었다(같은 변형)

## 재현 명령

빌드는 한 번, 테스트는 메서드 하나당 프로세스 하나로 돌리고 측정 줄만 로그로 남긴다.
로그의 경로·UDID 줄은 측정 후 지웠다. zsh에 붙여 넣을 수 있도록 블록 안에는 `#` 주석을 두지 않는다.

```bash
UDID=<UDID>
DD=/tmp/RephotoPerfDD
xcodebuild build-for-testing -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance -configuration Release \
  -destination "platform=iOS,id=$UDID" -derivedDataPath $DD ENABLE_TESTABILITY=YES
XCTESTRUN=$(ls $DD/Build/Products/*Performance*.xctestrun | head -1)

run() {
  xcodebuild test-without-building -xctestrun "$XCTESTRUN" \
    -destination "platform=iOS,id=$UDID" -only-testing:"$1" \
    -resultBundlePath "$2.xcresult" 2>&1 \
  | grep -E "🧪|run[0-9]:|measured|Test Case" > "$2.log"
}

for r in 1 2 3 4 5; do
  run Rephoto_iOSTests/UploadMemoryBenchmark/test_downsampleOptions_experiment options_run$r
done
for r in 1 2 3; do
  run Rephoto_iOSTests/UploadMemoryBenchmark/test_current_downsampleExtract_peakDelta extract_run$r
done
for t in A_lazy B_prepared C_cgdraw D_undownsampled; do for r in 1 2 3; do
  run Rephoto_iOSTests/DecodeVariantBenchTests/test_${t}_peakDelta decode_variants/${t}_run$r
done; done
for t in computedProperty_bodyEval100_photos100 computedProperty_bodyEval100_photos1000 \
         computedProperty_bodyEval100_photos10000 didSetCache_bodyEval100_photos100 \
         didSetCache_bodyEval100_photos1000 didSetCache_bodyEval100_photos10000 \
         didSetCache_photosAssign_10000 didSetCache_bodyEval10000_photos100 \
         didSetCache_bodyEval10000_photos1000 didSetCache_bodyEval10000_photos10000 \
         computedProperty_bodyEval10000_photos1000; do for r in 1 2 3; do
  run Rephoto_iOSTests/HomeDerivedCollectionPerformanceTests/test_$t home_derived/${t}_run$r
done; done
```

실제 `extract()` 출력 파일은 테스트 호스트(앱)의 임시 폴더에서 가져온다.

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.dodle.Rephoto-iOS --source tmp/benchmark.jpg --destination out.jpg
```

HEIC·피커 변환 JPEG 측정은 각각 `Fixtures/`에 그 파일 **한 장만** 두고 새 DerivedData 경로로 빌드했다.
`fixtureURL()`이 가장 큰 파일을 고르므로 더 큰 파일(예: `IMG_9898.jpeg`)이 같이 있으면 그쪽이 선택되고,
기존 빌드 폴더에는 지운 파일이 번들에 남아 있을 수 있다. 어느 파일을 썼는지는 로그의 `🧪 [입력]` 줄에 찍힌다.
