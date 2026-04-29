---
source_url: https://github.com/Mark-Yun/minglit/issues/2046
captured_at: 2026-04-29
issue_number: 2046
state: open
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-29: audit 정리 웨이브 성공 + dependabot 정체 + 법률 §50 PR 차단"
---

# ⚠️ TPM Report — 2026-04-29: audit 정리 웨이브 성공 + dependabot 정체 + 법률 §50 PR 차단

> Issue #2046 · open · created 2026-04-29 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2046

## Body

Scheduler: tpm-exec-report-claude-subagents

## Headline
- 어제(2026-04-28) audit 정리 웨이브 성공 — 30+ 이슈 closed / 16 PR merged.
- 백로그 사상 최저: 열린 이슈 10건, P0/P1 0건.
- 신규 운영 갭: dependabot PR 3건이 build 실패로 3~6일째 정체 → 처리 이슈 #2045 생성.
- 법률 §50 PR 2건(#2043 / #2044) CHANGES_REQUESTED 상태로 컴플라이언스 차단 → shepherd 코멘트 부착.
- runtime-qa ADB unreachable은 #2042로 이미 보고된 상태 그대로 (Mark 답변 대기).

## 1. 어제 처리량 (2026-04-28)

| 지표 | 수치 |
|------|------|
| 머지된 PR | 16 |
| 닫힌 이슈 (audit 포함) | 30+ |
| 새로 생성된 이슈 | 7 (대부분 hard block / legal audit) |
| 열린 이슈 (총) | 10 |
| P0/P1 열린 이슈 | 0 |

QA Audit #1998 + Arch Audit cluster의 결과로 #1937~#1972 대부분이 정리됨. RLS, refund, payment-webhook, CI permission 등 audit 대상 갭이 거의 비워졌다.

## 2. 법률 §50 컴플라이언스 PR 정체

| PR | 제목 | 상태 |
|----|------|------|
| #2043 | feat(notification-worker): 마케팅 푸시 §50 발송 가드 | BLOCKED · CHANGES_REQUESTED · CI green · 댓글 2 |
| #2044 | feat(consent): 마케팅 동의 2년 재확인 cron + landing privacy 정책 문서화 | BLOCKED · CHANGES_REQUESTED · CI green · 댓글 5 |

- 정보통신망법 §50 컴플라이언스가 직접 묶여 있어 출시 게이트.
- CI는 양쪽 모두 green — 코멘트 대응만 남음.
- TPM 액션 완료: 두 PR에 shepherd 코멘트 부착 (SWE/Arch 우선 처리 요청).

## 3. 신규 운영 갭: stale dependabot PR

| PR | 그룹 | 나이 | 실패 체크 |
|----|------|------|-----------|
| #1797 | ci-actions | 6일 | ci-result, auto-merge |
| #1862 | landing-partner-deps | 3일 | lint-and-build-landing-partner, ci-result, auto-merge |
| #1863 | landing-user-deps | 3일 | lint-and-build-landing-user, ci-result, auto-merge |

- auto-merge는 build 실패 PR을 self-heal 못 한다 — 보안 CVE 패치가 묶였을 위험.
- TPM 액션 완료: umbrella 이슈 #2045 생성, P2-medium + needs-swe.

## 4. runtime-qa ADB unreachable
- #2042 (4일 5건 누적) 그대로. Mark 답변 0건, 신규 hard block 0건.
- 새 시그널 없으므로 이번 사이클 별도 보고 안 함.

## 5. CI 안정성 (지난 24h)

| 워크플로우 | 성공 | 실패 |
|------------|------|------|
| CI (Unit/Widget/Golden/pgTAP/EF/Landing) | 2 | 1 |
| Auto Format PR | 3 | 0 |
| review-presence | 12 | 0 |
| Gitleaks | 3 | 0 |
| Dependabot Auto-Merge | 0 | 1 (반복) |
| Dependabot Updates | 1 | 0 |

- review-presence regression 없음 (#1768 재발 없음).
- Dependabot Auto-Merge 실패는 §3 PR들에 한정 — 워크플로우 자체 결함은 아님.

## 6. 백로그 점검 (열린 이슈 10건)
- 법률/컴플라이언스 (출시 게이트): #2043, #2044
- Hard block (운영): #1883, #2020, #2037, #2042
- 인프라 알림: #1917 (Vercel deploy)
- 기타: #1338, #1774

## TPM Action Items 완료 현황
- ✅ stale dependabot umbrella 이슈 → #2045 생성 (P2-medium, needs-swe).
- ✅ 법률 §50 PR shepherd 코멘트 → #2043, #2044에 부착.
- ✅ 본 리포트 report-exec 발행.
- ☐ docs/reports/tpm/ 동기화 (이슈 생성 직후).

## 사람 판단이 필요한 사안
- **#2042 (runtime-qa ADB unreachable 구조적 인프라 개선)**: 24시간 째 Mark 답변 대기. 출시 일정에 영향 — 이번 사이클에 결정 필요.
- 그 외 자동 처리 가능한 사안들은 위 액션 아이템으로 모두 라우팅함.
