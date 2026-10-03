# 업로드 전처리 15장 측정 — iPhone 14 Pro · iOS 27.2 developer beta (2026-10-03)

## 인용할 값

| 항목 | 중앙값 | 범위 (15장) | 비고 |
|---|---|---|---|
| 페이로드 (받은 사진 → 실제 업로드 파일) | **−73.1%** | −67.6 – −76.5% | 15장 합계 39.7MB → 11.1MB (−72.0%) |
| 다운샘플·인코딩 시간 A → D (경계 정렬 전 → 후) | **−24.7%** | −19.7 – −35.6% | 세로 13장 중앙값 −24.4%, 가로 2장 −33.0% · −35.6% |
| 회전을 고정한 정렬 효과 B → C | −34.2% | −27.8 – −35.5% | 참고 |

- 페이로드는 #34(다운샘플 + JPEG q0.8 재압축)의 효과, 시간은 #49(목표 크기를 JPEG 1/2ⁿ 디코드 경계에 맞춤)의 효과다.
- 세로 사진은 EXIF 방향대로 픽셀을 돌리는 비용(D − C, 중앙값 약 2ms)이 남아 개선 폭이 작다. 회전이 없는 가로 사진은 D ≈ C라 정렬 효과가 그대로 나온다.
- `extract()` 전체(EXIF 파싱 · 임시 파일 쓰기 포함)는 D보다 중앙값 약 1ms 더 걸린다.

## 측정 환경

```
측정일:        2026-10-03
기기 모델:      iPhone 14 Pro (iPhone15,2) — 실기기
iOS 버전:      27.2 developer beta (build 24B5089g) — 정식 릴리스 아님
빌드 구성:      Release / -O, SWIFT_COMPILATION_MODE = wholemodule, ENABLE_TESTABILITY=YES(커맨드라인)
테스트 플랜:    Rephoto_Performance, 테스트 1개씩 별도 프로세스
반복/집계:      test_downsampleOptions_experiment — 프로세스 5회 × 사진 15장 × 변형 4개 × 3회
               test_current_downsampleExtract_peakDelta — 프로세스 3회 × 사진 15장 × 5회
               시간은 사진·변형별로 각 프로세스의 1회차를 뺀 평균(옵션 실험 n=10, extract n=12)
시간 분해능:    0.1ms (로그 %.4f초)
```

## 입력

- iPhone 14 Pro 카메라 앱으로 찍은 12MP(4032×3024) 사진 15장. 세로 13장 · 가로 2장(EXIF 방향 기준).
- 렌즈(EXIF `LensModel` 기준)는 광각 9장 · 망원 3장 · 초광각 3장이다. 35mm 환산 14–154mm로 2배 크롭과 디지털 줌 사진도 섞여 있다.
- DEBUG 앱에서 `PhotosPicker`로 고른 뒤, 피커가 넘긴 데이터를 그대로 저장한 파일이다(= 앱이 실제로 받는 입력). 전부 JPEG.
- 다른 기기로 찍힌 사진 · 축소본 · 스크린샷은 뺐다. 사진 파일은 개인 사진(GPS 포함)이라 커밋하지 않는다. 로그에는 파일명(UUID)만 남는다.

## 사진별 결과

A: 회전 반영 · max 2048(#49 이전 앱) / B: 회전 안 함 · max 2048 / C: 회전 안 함 · 정렬값 / D: 회전 반영 · 정렬값(현재 앱).
정렬값은 앱과 같은 공식(긴 변을 2로 나눠 2048 이하가 되는 첫 값)으로 사진마다 계산했고, 15장 모두 2016이다.

| 사진 | 출력 방향 | 받은 사진 → 업로드 파일 | 페이로드 | A (#49 이전) | D (현재) | A → D | B → C | D − C (회전 비용) | `extract()` |
|---|---|---|---|---|---|---|---|---|---|
| `37E6F0D7` | 세로 | 1,363,866 → 362,244 B | −73.4% | 21.85ms | 15.94ms | −27.0% | −35.5% | +2.06ms | 18.12ms |
| `502406CE` | 세로 | 5,483,371 → 1,605,825 B | −70.7% | 25.25ms | 19.94ms | −21.0% | −29.4% | +2.30ms | 22.52ms |
| `52E2BBE5` | 세로 | 3,571,903 → 915,799 B | −74.4% | 23.92ms | 18.57ms | −22.4% | −31.5% | +2.15ms | 19.32ms |
| `54F59859` | 세로 | 2,228,735 → 598,739 B | −73.1% | 21.36ms | 15.95ms | −25.3% | −34.9% | +2.12ms | 17.10ms |
| `587306D8` | 세로 | 5,871,533 → 1,502,113 B | −74.4% | 26.66ms | 21.41ms | −19.7% | −27.8% | +2.13ms | 22.46ms |
| `66055B8E` | 세로 | 2,372,869 → 659,802 B | −72.2% | 21.81ms | 16.59ms | −23.9% | −34.2% | +2.22ms | 17.20ms |
| `67BD1CF3` | 세로 | 3,980,526 → 1,287,775 B | −67.6% | 22.57ms | 17.11ms | −24.2% | −33.2% | +2.05ms | 18.50ms |
| `833E3864` | 세로 | 1,684,879 → 523,163 B | −68.9% | 20.85ms | 15.78ms | −24.3% | −34.8% | +2.19ms | 16.48ms |
| `9003DABA` | 세로 | 2,954,854 → 868,764 B | −70.6% | 22.21ms | 16.64ms | −25.1% | −34.2% | +2.11ms | 17.39ms |
| `90B7B149` | 세로 | 1,890,001 → 495,082 B | −73.8% | 21.45ms | 16.15ms | −24.7% | −34.6% | +2.24ms | 16.75ms |
| `9700DCE6` | 가로 | 1,975,962 → 464,401 B | −76.5% | 21.58ms | 13.90ms | −35.6% | −35.2% | +0.13ms | 14.46ms |
| `B889BB8E` | 세로 | 1,686,868 → 447,029 B | −73.5% | 21.29ms | 15.99ms | −24.9% | −35.1% | +2.19ms | 16.73ms |
| `D8B22651` | 세로 | 2,654,822 → 777,184 B | −70.7% | 21.95ms | 16.53ms | −24.7% | −33.7% | +2.04ms | 18.01ms |
| `F36DA221` | 가로 | 3,164,585 → 941,889 B | −70.2% | 21.71ms | 14.55ms | −33.0% | −32.8% | −0.09ms | 15.73ms |
| `F722FE3B` | 세로 | 756,814 → 202,334 B | −73.3% | 20.80ms | 15.73ms | −24.4% | −34.7% | +2.18ms | 16.80ms |

## 참고 — 메모리 (인용하지 않음)

네 변형을 한 프로세스에서 이어 돌리는 구조라 변형 간 메모리 비교 근거로 쓰지 않는다(`TESTING.md` 「측정 설계에서 반드시 지켜야 할 세 가지」 ③).

## 직접 확인하는 법

- **회차별 원문**: `options_run1–5.log`, `extract_run1–3.log`. 사진마다 `🧪 [입력] <파일명> … <바이트>B` 줄 뒤에 변형별 `run` 줄이 이어진다.
- **재계산**: `run` 줄의 시간 열을 사진·변형별로 모아 1회차를 빼고 평균을 내면 위 표와 같다. 페이로드는 `[입력]` 줄의 바이트와 extract 로그의 `out …B`로 계산한다.
- **Xcode 결과 번들**(로컬 전용, `.gitignore`): 같은 이름의 `.xcresult`.

## 재현 명령

`Fixtures/`에 사진을 넣고(전부 돈다), 빌드는 한 번, 테스트는 메서드 하나당 프로세스 하나로 돌린다. zsh에 붙여 넣을 수 있도록 블록 안에는 주석을 두지 않는다.

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
  | grep -E "🧪|run[0-9]:|Test Case" > "$2.log"
}

for r in 1 2 3 4 5; do
  run Rephoto_iOSTests/UploadMemoryBenchmark/test_downsampleOptions_experiment options_run$r
done
for r in 1 2 3; do
  run Rephoto_iOSTests/UploadMemoryBenchmark/test_current_downsampleExtract_peakDelta extract_run$r
done
```

입력 사진은 DEBUG 앱에서 고른 뒤 앱의 `tmp/`를 가져와 만든다.

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.dodle.Rephoto-iOS --source tmp --destination picker
```
