# 빌드 시간 — Tuist 멀티모듈 전환 전후

단일 타깃(`Rephoto_iOS.xcodeproj`)과 Tuist 워크스페이스(`Rephoto/`)의 빌드 시간을 같은 절차로 쟀다.

## 결과

같은 날 같은 환경에서 잰 값이다(2026-11-16, 3회 중앙값).

| 항목 | 전환 전 (단일 타깃) | 전환 후 (Tuist) | 변화 |
| --- | --- | --- | --- |
| 증분 빌드 | 3.28초 | 2.03초 | **−38%** |
| 클린 빌드 | 6.62초 | 7.29초 | +10% |

- **증분이 줄어든 이유**: `HomeView.swift` 한 줄을 고치면 단일 타깃은 앱 모듈 전체가 다시 빌드 대상이 되지만, Tuist에서는 `HomeFeature` 모듈과 앱 링크만 다시 돈다고 본다(빌드 로그로 단계별 확인은 하지 않았다).
- **클린이 늘어난 이유**: 타깃이 1개에서 모듈 11개 + 앱으로 늘어 타깃마다 컴파일 · 링크 단계가 따로 돈다고 본다.

평소 개발에서 반복되는 것은 증분 빌드다.

## 구조 지표

| 항목 | 전환 전 | 전환 후 |
| --- | --- | --- |
| 모듈 | 1 | 11 + 앱 |
| `public` | 11 | 319 |
| `@MainActor` | 16 | 8 |

`public`이 늘어난 것은 모듈 경계를 넘는 타입을 드러내야 해서다. `@MainActor`가 줄어든 것은 UI 모듈의 기본 격리를 `MainActor`로 두어 타입마다 붙일 필요가 없어졌기 때문이다.
전환 후 값은 `Projects/`의 `Sources` · `Interface`만 센 것이다(Tests · Testing · Example 제외).

## 측정값

| 측정 | 구성 | 워밍업 | 클린 1 · 2 · 3 | 중앙값 | 증분 1 · 2 · 3 | 중앙값 |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-16 | Tuist | 13.67 | 7.31 · 7.19 · 7.29 | 7.29 | 2.17 · 2.03 · 2.03 | 2.03 |
| 2026-11-16 | 단일 타깃 | 14.64 | 6.62 · 8.14 · 6.37 | 6.62 | 3.39 · 3.28 · 2.69 | 3.28 |
| 2026-10-29 | 단일 타깃 (`e3d3ddd`) | 12.14 | 6.13 · 6.14 · 6.15 | 6.14 | 3.09 · 2.84 · 2.65 | 2.84 |

단위는 초다. 2026-10-29 기준값과 비교하면 증분 −29%, 클린 +19%다. Xcode와 macOS가 달라 위 표의 비교에는 같은 날 다시 잰 단일 타깃 값을 썼다.

## 환경

| | 2026-11-16 | 2026-10-29 |
| --- | --- | --- |
| Mac | MacBook Air (M4) · 16GB | 같음 |
| macOS | 27.3 | 27.2 |
| Xcode | 27.2 (27B52) | 27.1 (27A9275) |
| 목적지 | iPhone 18 Pro 시뮬레이터 | 같음 |
| 코드 | `583248b` + 앱 아이콘 · 성능 테스트 타깃 추가(미커밋) | `e3d3ddd` |

- 워밍업 1회 후 클린 · 증분 각 3회, `/usr/bin/time -p`의 real 값. 모든 회차 `exit=0`
- 클린: `xcodebuild clean` 후 빌드. 모듈 캐시와 SPM 체크아웃은 남으므로 캐시가 전혀 없는 콜드 빌드와는 다르다
- 증분: `HomeView.swift` 끝에 주석 한 줄을 추가한 뒤 빌드
- DerivedData는 iCloud 밖(`~/Library/Developer/Xcode/`)에 둔다. 레포가 iCloud 경로라 안에 두면 CodeSign이 실패한다

## 재현

레포 루트에서 실행한다. 단일 타깃은 주석 처리된 두 줄로 바꾼다.

```bash
DD="$HOME/Library/Developer/Xcode/BaselineDD"
DEST='platform=iOS Simulator,name=iPhone 18 Pro'
LOG=/tmp/rephoto_build.log
TARGET=(-workspace Rephoto/Rephoto.xcworkspace -scheme Rephoto)
HV=Rephoto/Projects/Feature/Home/Sources/Views/HomeView.swift
# TARGET=(-project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS)
# HV=Rephoto_iOS/Features/Home/Presentation/Views/HomeView.swift

run() { /usr/bin/time -p xcodebuild build "${TARGET[@]}" -destination "$DEST" -derivedDataPath "$DD" -quiet > "$LOG" 2>&1; s=$?; echo "$1 exit=$s $(grep '^real' "$LOG")"; [ $s -ne 0 ] && grep -m3 -E 'error|failed' "$LOG"; }

(
BK=$(mktemp "${TMPDIR:-/tmp}/HomeView.XXXXXX") || exit 1
cp "$HV" "$BK" || exit 1
trap 'cp "$BK" "$HV" && rm -f "$BK"' EXIT
trap 'exit 130' INT TERM

run warmup
for i in 1 2 3; do
  if xcodebuild clean "${TARGET[@]}" -destination "$DEST" -derivedDataPath "$DD" -quiet; then run "clean$i"; else echo "clean$i 실패: 측정에서 제외"; fi
done
for i in 1 2 3; do echo "// touch $i" >> "$HV"; run "incr$i"; done
rm -rf "$DD"
)
```

- `HomeView.swift`를 임시 파일에 백업하고, 끝나거나 중단되면 복원한다.
- clean이 실패한 회차는 산출물이 남아 클린 값이 아니므로 뺀다.
