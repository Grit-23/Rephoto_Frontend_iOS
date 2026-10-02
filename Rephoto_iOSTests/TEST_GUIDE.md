# Rephoto iOS 성능 벤치마크 테스트 가이드

측정 전용 벤치마크 18개의 구성과 측정 대상. 측정 결과는 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md),
실기기 실행 절차는 [`TESTING.md`](TESTING.md)에 있다. 회귀 baseline(xcbaseline)은 두지 않는다.

> 2026-10-03: 회귀 감시용 스위트 5개(`Decoding` · `Mapping` · `Memory` · `PhotoInfo` · `Token`, 19개)와 xcbaseline을 삭제했다.
> 기준값을 재현할 수 없었기 때문이다(`BASELINE_RESULTS.md` 「측정 환경」). 그 전의 구성은 git 히스토리에 있다.

---

## 테스트 파일 구성 (18개)

`HomeDerivedCollectionPerformanceTests`(11) · `UploadMemoryBenchmark`(3) · `DecodeVariantBenchTests`(4).
`Rephoto_Performance` 플랜으로 수동 실행하고, PR 게이트(`Rephoto_iOS` 플랜)에서는 건너뛴다.

### `Support/MockDataFactory.swift`
공용 Mock 데이터 생성 팩토리. `HomeDerivedCollectionPerformanceTests`가 쓴다.

---

### `HomeDerivedCollectionPerformanceTests.swift` (A/B 실측)

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
> 판정되어 컴파일러가 읽기를 루프 밖으로 빼낸 것으로 보인다(디스어셈블로 확인하지 않음). 평가 10,000회 테스트에서 드러났다 —
> A는 반복 100배에 106배가 되는데 B는 2.7–3.1배에 그친다(2026-10-02 iPhone 14 Pro).
> B의 평가당 절대값은 인용하지 말 것. 근거는 `BASELINE_RESULTS.md`.

---

### `UploadMemoryBenchmark.swift` (측정 전용)

업로드 전처리(#34 ImageIO 다운샘플)의 처리 시간·출력 크기와 메모리 피크를 찍는다. 인용하는 값은 페이로드와 처리 시간이고,
메모리는 변형 간 비교 근거로 쓰지 않는다(`BASELINE_RESULTS.md`). 메모리는 `XCTMemoryMetric` 대신
`task_vm_info.phys_footprint` 폴링으로 작업 구간의 피크 증가분(delta)을 잰다 — 프로세스 전체
피크에 셋업 메모리가 섞이는 오염을 피하기 위함. 결과는 콘솔 출력.

입력으로 원본 해상도 사진이 필요한데 개인 EXIF 때문에 커밋하지 않는다. `fixtureURL()`이
`Rephoto_iOSTests/Performance/Fixtures/`(테스트 번들 동봉 — 실기기용) → 리포 루트
`MockImagesReal/`(호스트 — 시뮬레이터용) 순으로 찾고, 둘 다 없으면 **자동 스킵**된다.
앱 타겟 `Resources/`에는 두지 말 것 — `MockImages`와 파일명이 겹쳐 번들 복사 충돌이 난다.
실기기 + Release 실행 절차는 [`TESTING.md`](TESTING.md), 측정 수치는 `BASELINE_RESULTS.md` 참조.

| 테스트 | 측정 대상 |
|---|---|
| `test_undownsampledReencode_peakDelta` | 다운샘플 없는 대조군: UIImage 전체 디코드 + JPEG 재인코딩 (#34 이전 앱의 재현 아님 — #34 이전 앱은 받은 사진을 그대로 업로드) |
| `test_current_downsampleExtract_peakDelta` | 현재: `PhotoMetadataExtractor.extract` (원본 기반 목표 크기로 썸네일 디코드 — 4032px 원본이면 2016px) |
| `test_downsampleOptions_experiment` | 다운샘플 옵션(목표 크기·경계 정렬) 조합별 실험 — #49 경계 정렬 근거 |

---

### `DecodeVariantBenchTests.swift` (측정 전용)

위 다운샘플 없는 대조군의 메모리 피크(시뮬레이터 +19MB, 실기기 +9.8MB)가 어디서 온 값인지 가르는 대조 실험.
`UIImage` lazy decoding 때문에 디코드를 안 한 것인지, YUV 4:2:0으로 푼 것인지를
네 변형(`A_lazy` / `B_prepared` / `C_cgdraw` / `D_undownsampled`)을 같은 세션에서 찍어 비교한다.

입력과 `FootprintSampler`는 `UploadMemoryBenchmark`와 공유하므로 스킵 조건도 동일하다
(`Fixtures/`·`MockImagesReal/` 둘 다 없으면 자동 스킵). 목적·변형 정의·실행 명령은 [`TESTING.md`](TESTING.md),
결과 기록은 [`BASELINE_RESULTS.md`](BASELINE_RESULTS.md)에 있다.

| 테스트 | 측정 대상 |
|---|---|
| `test_A_lazy_peakDelta` | `UIImage(data:)`만 — 디코드 강제 없음 |
| `test_B_prepared_peakDelta` | `preparingForDisplay()` — 플랫폼이 고른 픽셀 포맷 |
| `test_C_cgdraw_peakDelta` | RGBA 8bit `CGContext` draw — 강제 풀디코드 |
| `test_D_undownsampled_peakDelta` | 기존 다운샘플 없는 대조군의 복사본 |

변형별 독립 메서드로 나뉜 이유, 집계에 중앙값을 쓰지 않는 이유는 [`TESTING.md`](TESTING.md)의
"측정 설계에서 반드시 지켜야 할 세 가지"에 있다. 순서 의존성을 없애려면 `-only-testing`으로
하나씩 실행한다.
