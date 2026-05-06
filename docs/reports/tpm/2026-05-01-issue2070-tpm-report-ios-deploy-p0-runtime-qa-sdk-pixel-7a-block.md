---
source_url: https://github.com/Mark-Yun/minglit/issues/2070
captured_at: 2026-05-01
issue_number: 2070
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-05-01: iOS Deploy 양쪽 P0 + runtime-qa SDK 3.41 hard block + Pixel 7a 4일째"
---

# ⚠️ TPM Report — 2026-05-01: iOS Deploy 양쪽 P0 + runtime-qa SDK 3.41 hard block + Pixel 7a 4일째

> Issue #2070 · open · created 2026-05-01 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2070

## Body

Scheduler: tpm-exec-report-claude-subagents

## Headline

- 어제~오늘(2026-04-30 → 05-01) 신규 P0 인프라 차단 2건 동시 발생: **iOS Deploy User/Partner 양쪽 모두 실패** (#2049 1일째 / #2061 18시간째). Apple Developer 계정 접근이 필요해 사람 판단 필요.
- 신규 hard block: **runtime-qa 환경 Flutter SDK 3.38.5 < mds_icons 요구 3.41.0** (#2064). 디바이스가 아니라 워커 SDK 자체 정체.
- Pixel 7a Hard Block(#1883)이 4일째 미해결, 새 워커가 진입할 때마다 동일 실패 반복 — 13개 코멘트 누적.
- audit-report #2063 트리아지 완료 → actionable #2069 (P2, partner avatar MinglitAvatarImage 마이그레이션)로 변환.
- 백로그 건강도는 양호 — 열린 이슈 11건(P0 4건, P1/P2 0건+2069 P2 신규, 나머지 report-exec/runtime-qa 알림). PR 머지율 92% (100건 중 92건).

## 1. 사람 판단 필요 사항 (이번 리포트의 핵심)

### A. iOS Deploy 양쪽 P0 동시 실패

| 이슈 | 워크플로 | Run | 첫 발생 | 경과 |
|------|----------|-----|---------|------|
| #2049 | iOS Deploy User | runs/25106054256 | 2026-04-29 11:34Z | ~25h |
| #2061 | iOS Deploy Partner | runs/25162701016 | 2026-04-30 11:32Z | ~18h |

- 둘 다 dev 브랜치 cron 트리거, body는 `❌ ios-deploy: failure` 한 줄.
- 동시 실패 패턴이라 코드 회귀보다는 **인증서/프로비저닝 프로파일 만료, App Store Connect API 키, Fastlane 토큰** 같은 외부 자격증명 만료가 의심됨.
- swe가 자체 해결 불가 — Mark가 Apple Developer 계정에 직접 들어가 확인해야 함.
- **요청**: Apple Developer 계정에서 인증서/프로비저닝 프로파일 만료일 확인 + Fastlane Match/secret 갱신 여부 점검.

### B. runtime-qa Flutter SDK 3.41.0 unblock

이슈 #2064.
- `mds_icons` 패키지가 SDK ≥ 3.41.0을 요구하지만 runtime-qa 워커 환경은 3.38.5.
- 옵션:
  1. **워커 SDK를 3.41.0+로 업그레이드** (Mark가 워커 셋업 보유). 권장.
  2. `mds_icons`의 SDK constraint를 3.38.5까지 낮춤. 패키지 PoC 단계라 가능은 하지만 #1969의 의도(최신 SDK 활용)와 충돌.
- **요청**: 워커 SDK 업그레이드 진행 여부 결정. 결정 안 나면 runtime-qa가 모든 신규 변경 검증 못 함.

### C. Pixel 7a Hard Block (#1883) 4일째 미해결

- 워커들이 매번 진입할 때마다 동일 디바이스 미연결 실패를 코멘트로 남겨 13건 누적.
- 디바이스를 USB/무선으로 다시 붙이거나, runtime-qa가 다른 디바이스로 fallback하는 정책 결정 필요.
- **요청**: Pixel 7a 재연결 또는 대체 단말 정책 결정.

## 2. 진행 중 운영 갭 (작업자가 처리 가능, 참고용)

| 항목 | 상태 | 다음 액션 |
|------|------|----------|
| #1917 Vercel Deploy 실패 | 4일째, P0 라벨 | swe가 root cause 추적 중인지 라벨 재부여 검토 (지금은 report-exec만 붙어 있음) |
| 법률 §50 PR #2043 / #2044 | CHANGES_REQUESTED · CI green | swe 코멘트 대응 대기 (#2046에서 이미 shepherd 부착) |
| dependabot PR #2048 | BLOCKED, build 실패 | #2045 swe 처리 흐름 안에서 함께 정리 |
| #2018 (onlyhyeok-cmd 테스트 PR) | 3일째 BLOCKED | review 또는 close 판단 필요 |
| 신규 P3 #2068 | needs-swe (color tokens) | 정상 흐름 |
| 신규 P2 #2069 | needs-swe (partner avatar) | 정상 흐름 (이번 사이클에서 audit#2063에서 변환) |

## 3. 메트릭 (최근 7일)

| 지표 | 수치 |
|------|------|
| 새 이슈 | 121 (open 10 / closed 111, 종료율 92%) |
| PR 생성 | 100 (Mark-Yun 98, dependabot 1, onlyhyeok-cmd 1) |
| PR 머지 | 92 (머지율 92%) |
| 새 이슈 라벨 분포 | needs-swe 60 · P2 44 · bug 37 · P3 31 · bug-report 21 · P1 17 · refactor 14 · P0 4 |
| review-presence 워크플로 | 23회 / 5 fail (22% 실패율, 단 required 아님) |
| Vercel Deploy 워크플로 | 2/2 실패 (#1917) |
| 메인 CI(Unit+Widget+Golden+pgTAP+EF+Landing Lint) | 3/3 success — 견고 |

## 4. 트리아지 결과

- audit-report #2063 → actionable #2069 (P2 + needs-swe). 원본 close.
- 미아 이슈(라벨 없음): 0건.
- 라벨 정리 필요한 stale 이슈 4건은 모두 report-exec 카테고리라 닫지 않고 유지.

## 5. 결론

- **블로킹 사안 3개 모두 사람 판단/물리 액세스가 필요한 영역** (Apple 자격증명, 워커 SDK, 물리 디바이스). swe에게 넘길 수 없음.
- 코드 사이드는 양호 — 메인 CI green, 머지 흐름 정상, P0 이슈는 모두 인프라성.
