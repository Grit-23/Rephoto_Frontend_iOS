# 디코드 변형 · 파생 컬렉션 재측정 — iPhone 14 Pro · iOS 27.2 developer beta (2026-10-02)

`BASELINE_RESULTS.md`의 `DecodeVariantBenchTests` · `HomeDerivedCollectionPerformanceTests` 수치를 원본 로그와 함께 다시 잰 기록이다.
이전 측정(2026-08-02·03)은 콘솔 원문이 남아 있지 않아 이번에는 **회차별 원문을 이 폴더에 보존**한다.
업로드 전처리 측정은 [`2026-10-03_iPhone14Pro_15photos/`](../2026-10-03_iPhone14Pro_15photos/README.md)에 있다.

## 측정 환경

```
측정일:        2026-10-02
기기 모델:      iPhone 14 Pro (iPhone15,2 · A16) — 실기기
iOS 버전:      27.2 developer beta (build 24B5089g) — 정식 릴리스 아님
Xcode:         27.1 (27A9269)
빌드 구성:      Release / -O, SWIFT_COMPILATION_MODE = wholemodule
               ENABLE_TESTABILITY=YES (커맨드라인 오버라이드 — TESTING.md 절차)
테스트 플랜:    Rephoto_Performance, -only-testing으로 테스트 1개씩 별도 프로세스 실행
반복/집계:      DecodeVariantBenchTests 4개 · HomeDerivedCollectionPerformanceTests 11개 — 각 프로세스 3회 × 5회
입력:          IMG_9898.jpeg 4032×3024 (5,871,533 B) — DecodeVariantBenchTests 전용
```

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

- **회차별 원문**: `decode_variants/<변형>_run1–3.log`, `home_derived/<테스트>_run1–3.log`.
  로그는 측정 줄만 남기도록 `grep`으로 거르고, 로컬 경로·기기 UDID가 든 줄은 지웠다(측정값 줄은 원문 그대로)
- **Xcode 결과 번들** (로컬 전용, `.gitignore`): 같은 이름의 `.xcresult`를 더블클릭 → Report 내비게이터에서 테스트 선택 → 콘솔 출력
- **재계산**: 로그의 `run` 줄(디코드 변형)과 `measured` 줄(파생 컬렉션)의 값을 모아 평균을 내면 위 표와 같다

## 재현 명령

빌드는 한 번, 테스트는 메서드 하나당 프로세스 하나로 돌리고 측정 줄만 로그로 남긴다.
zsh에 붙여 넣을 수 있도록 블록 안에는 `#` 주석을 두지 않는다.

```bash
UDID=<UDID>
DD=/tmp/RephotoPerfDD
xcodebuild build-for-testing -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS \
  -testPlan Rephoto_Performance -configuration Release \
  -destination "platform=iOS,id=$UDID" -derivedDataPath $DD ENABLE_TESTABILITY=YES
XCTESTRUN=$(ls $DD/Build/Products/*Performance*.xctestrun | head -1)
mkdir -p decode_variants home_derived

run() {
  xcodebuild test-without-building -xctestrun "$XCTESTRUN" \
    -destination "platform=iOS,id=$UDID" -only-testing:"$1" \
    -resultBundlePath "$2.xcresult" 2>&1 \
  | grep -E "🧪|run[0-9]:|measured|Test Case" > "$2.log"
}

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

`DecodeVariantBenchTests`는 `fixtureURL()`로 `Fixtures/`에서 가장 큰 파일 한 장을 고른다. 2026-10-03 이후 `Fixtures/`의 15장 중 가장 큰 파일도 같은 `IMG_9898`(5,871,533 B)이다.
