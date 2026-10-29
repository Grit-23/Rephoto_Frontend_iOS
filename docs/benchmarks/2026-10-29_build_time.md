# 빌드 시간 기준값 (e3d3ddd)

Tuist 멀티모듈 전환(#90) 전 단일 타깃의 빌드 시간. 전환 후 같은 절차로 재측정해 after 열을 채운다.

## 환경
- Mac: MacBook Air 13형 (M4, 2025) · 16GB
- macOS 27.2
- Xcode 27.1 (27A9275)
- iPhone 18 Pro 시뮬레이터 (iOS 27.0)
- DerivedData: `~/Library/Developer/Xcode/BaselineDD` (iCloud 밖)
- 워밍업 1회 후 클린·증분 각 3회, `/usr/bin/time -p` real 값. 7회 모두 `exit=0`
- 클린: `xcodebuild clean` 후 빌드. clean은 빌드 산출물만 지우고 모듈 캐시·SPM 체크아웃은 남기므로, 캐시가 전혀 없는 콜드 빌드와는 다르다
- 증분: `HomeView.swift` 끝에 주석 한 줄 추가 후 빌드

## 결과
| 항목 | 1회 | 2회 | 3회 | 중앙값 | after |
| --- | --- | --- | --- | --- | --- |
| 클린 빌드 (초) | 6.13 | 6.14 | 6.15 | 6.14 | |
| 증분 빌드 (초) | 3.09 | 2.84 | 2.65 | 2.84 | |

워밍업: 12.14초

## 구조 지표
| 항목 | before | after |
| --- | --- | --- |
| 모듈 | 1 | |
| `public` | 11 | |
| `@MainActor` | 16 | |

## 재현
리포가 iCloud Drive 경로에 있어서 DerivedData를 리포 안에 두면 iCloud가 붙인 확장 속성 때문에 CodeSign이 실패한다(`resource fork, Finder information, or similar detritus not allowed`). DerivedData는 반드시 iCloud 밖에 둔다.

```bash
DD="$HOME/Library/Developer/Xcode/BaselineDD"
DEST='platform=iOS Simulator,name=iPhone 18 Pro'
LOG=/tmp/rephoto_build.log
HV=Rephoto_iOS/Features/Home/Presentation/Views/HomeView.swift

run() { /usr/bin/time -p xcodebuild build -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS -destination "$DEST" -derivedDataPath "$DD" -quiet > "$LOG" 2>&1; s=$?; echo "$1 exit=$s $(grep '^real' "$LOG")"; [ $s -ne 0 ] && grep -m3 -E 'error|failed' "$LOG"; }

(
BK=$(mktemp "${TMPDIR:-/tmp}/HomeView.XXXXXX") || exit 1
cp "$HV" "$BK" || exit 1
trap 'cp "$BK" "$HV" && rm -f "$BK"' EXIT
trap 'exit 130' INT TERM

run warmup
for i in 1 2 3; do
  if xcodebuild clean -project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS -destination "$DEST" -derivedDataPath "$DD" -quiet; then run "clean$i"; else echo "clean$i 실패: 측정에서 제외"; fi
done
for i in 1 2 3; do echo "// touch $i" >> "$HV"; run "incr$i"; done
rm -rf "$DD"
)
```

- 서브셸 안에서 `HomeView.swift`를 임시 파일에 백업하고, 정상 종료든 `^C` 중단이든 끝나면 백업본으로 복원한다. 커밋하지 않은 수정도 유지된다.
- clean이 실패한 회차는 산출물이 남은 상태라 클린 수치가 아니므로 측정에서 뺀다.

Tuist 전환 후에는 `-project Rephoto_iOS.xcodeproj -scheme Rephoto_iOS`를 `-workspace Rephoto.xcworkspace -scheme Rephoto`로, 증분 대상 파일을 `Projects/Feature/Home/Sources/` 아래 `HomeView.swift`로 바꿔 같은 절차로 측정한다.
