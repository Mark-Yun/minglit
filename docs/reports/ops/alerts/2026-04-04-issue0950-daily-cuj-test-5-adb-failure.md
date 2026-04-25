---
source_url: https://github.com/Mark-Yun/minglit/issues/950
captured_at: 2026-04-04
issue_number: 950
state: closed
labels: [ci-failure, P2-medium, report-exec]
author: Mark-Yun
title: "🚨 Daily CUJ 테스트 5일 연속 adb 실패 — 인프라 점검 필요"
---

# 🚨 Daily CUJ 테스트 5일 연속 adb 실패 — 인프라 점검 필요

> Issue #950 · closed · created 2026-04-04T01:09:17Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/950

## Body

Scheduler: audit-qa-claude-1

### 상황

Daily Backend Simulation + CUJ Tests 워크플로우가 2026-03-30부터 2026-04-03까지 **5일 연속** 실패 중.

실패 원인:
```
The process '/usr/local/lib/android/sdk/platform-tools/adb' failed with exit code 1
The process '/usr/bin/sh' failed with exit code 127 (command not found)
```

- `partner-cuj-test`, `client-cuj-test` 두 job 모두 동일 패턴
- adb가 반복적으로 exit code 1 반환 (연결 실패)
- 일부 실행에서 `sh` exit code 127 (runner 환경 이슈)

### 판단이 필요한 이유

- 코드 문제가 아닌 인프라/runner 설정 문제로 판단됨
- GitHub Actions Android 에뮬레이터 설정 또는 KVM 활성화 이슈 가능성
- QA 워커가 직접 runner 설정을 변경할 수 없음

### 선택지

| 옵션 | 장점 | 단점 |
|------|------|------|
| A. GitHub Actions runner 에뮬레이터 설정 점검/수정 | 근본 해결 | 인프라 작업 필요 |
| B. CUJ 워크플로우 일시 비활성화 | 노이즈 제거 | E2E 회귀 탐지 상실 |
| C. 현행 유지 | 노력 없음 | 5일 이상 E2E 커버리지 공백 |

### 워커 의견

**옵션 A 권장.** 7월 출시 전 E2E 커버리지는 필수. adb 연결 실패는 보통 에뮬레이터 설정(`avdmanager`, KVM 권한, API level 불일치)에서 발생하므로 `.github/workflows/daily-simulation.yml` 내 에뮬레이터 초기화 단계 점검 권장.

참고 이슈: QA 일일 리포트 #949

## Comments (6)

### Comment 1 — @Mark-Yun on 2026-04-04

## Root Cause 분석

### 원인: `android-emulator-runner@v2`의 script 실행 셸 불일치

`reactivecircus/android-emulator-runner@v2`의 `script` 파라미터는 기본적으로 `/usr/bin/sh`로 실행됩니다.

**partner-cuj-test (exit code 127)**
```
/usr/bin/sh -c shopt -s nullglob
/usr/bin/sh: 1: shopt: not found
```
- `shopt`은 **bash 전용** builtin. `sh`에서 사용 불가.

**client-cuj-test (exit code 2)**
```
for f in integration_test/*_test.dart; do
```
- `sh`에서는 glob 매칭 실패 시 리터럴 문자열이 전달 → `flutter test`가 존재하지 않는 파일을 받아 실패.

### 현재 상태
- `app_user/integration_test/`: 테스트 2개 (`apple_sign_in_test.dart`, `party_browse_test.dart`)
- `app_partner/integration_test/`: 테스트 0개

### 수정 방안

두 job의 `android-emulator-runner` step에 `shell: bash` 추가:

```yaml
- uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 33
    arch: x86_64
    profile: pixel_6
    shell: bash        # ← 추가
    script: |
      ...
```

이것만으로 `shopt`, bash globbing 모두 정상 동작합니다.

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 swe-sonnet-subagents-3 작업 시작합니다. root cause 분석 완료 — android-emulator-runner shell: bash 추가로 수정합니다.

### Comment 3 — @Mark-Yun on 2026-04-04

PR #977 생성 완료: https://github.com/Mark-Yun/minglit/pull/977

**수정 내용:**
- `client-cuj-test`: unmatched glob 대비 `[ -f "$f" ] || break` 가드 추가
- `partner-cuj-test`: `shopt -s nullglob` + bash 배열 → POSIX-호환 `found=0` / `[ -f "$f" ] || break` 패턴으로 교체

auto-merge 설정 완료. CI 통과 시 자동 squash merge됩니다.

### Comment 4 — @Mark-Yun on 2026-04-04

코드 리뷰 완료 (code-reviewer). PR #977 diff 검토:

- POSIX 호환 null glob 처리 패턴 정확함
- app_user/app_partner 양쪽 처리 일관적
- 기존 exit 0 제거 → 자연 종료로 동등함
- ci-result: PASS (branch update 후 재실행 대기 중)

자체 PR 승인은 GitHub 정책상 불가하나, 코드 품질에 문제 없음. CI 통과 후 auto-merge 예정.

### Comment 5 — @Mark-Yun on 2026-04-04

🤖 **tpm-exec-report-claude-subagents** 라벨 정리: `needs-review` 제거. PR #977이 리뷰 대기 중이며, 이 이슈 자체는 인프라 점검이 필요한 `report-exec` 상태를 유지합니다.

### Comment 6 — @Mark-Yun on 2026-04-04

PR #977 머지 완료 (2026-04-04T07:04:52Z). CUJ 스크립트 POSIX 호환 수정 dev에 반영됨.
