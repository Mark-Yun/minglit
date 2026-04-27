---
source_url: https://github.com/Mark-Yun/minglit/issues/1046
captured_at: 2026-04-04
issue_number: 1046
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-05: Seed Dev 자동 이슈 반복 생성 (15건) — 워크플로우 조건 수정 필요"
---

# ⚠️ TPM Report — 2026-04-05: Seed Dev 자동 이슈 반복 생성 (15건) — 워크플로우 조건 수정 필요

> Issue #1046 · closed · created 2026-04-04T17:24:25Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1046

## Body

Scheduler: tpm-exec-report-claude-subagents

## 요약

"Seed Dev failed on dev" 자동 생성 이슈가 **총 15건** 발생 (03-26 ~ 04-05). 대부분 transient failure 또는 false positive (seeder skipped)로 수동 닫힘 처리되고 있음.

## 데이터

| 날짜 | 건수 | 이슈 번호 |
|------|------|----------|
| 04-04 | 4건 | #1004, #1015, #1031, #1045 |
| 03-30 | 5건 | #837, #873, #889, #894, #906 |
| 03-29 | 2건 | #787, #816 |
| 03-28 | 3건 | #646, #668, #669 |
| 03-26 | 1건 | #456 |

## 근본 원인

1. `Seed Dev` 워크플로우의 `notify-failure` job이 **seeder skip 상태에서도 P0 이슈를 생성**함
   - 예: #1045 — 전체 run conclusion: `success`, Run Seeder: `skipped`, 그런데도 이슈 생성됨
2. Transient failure (일시적 네트워크/서비스 오류)에도 P0 이슈 생성 → 노이즈

## 영향

- TPM이 매 사이클마다 false positive P0 이슈를 확인/닫는 데 시간 소모
- P0 라벨의 신뢰도 하락 (실제 P0 이슈와 noise 구분 어려움)
- SWE 워커가 false positive에 반응하여 불필요한 작업 가능

## 권장 조치 (사람 판단 필요)

### 옵션 A: 실패 판정 조건 수정 (권장)
- `notify-failure` job에서 seeder가 `skipped`인 경우 이슈 생성하지 않도록 조건 추가
- Transient failure 시 자동 재시도 (1~2회) 후 여전히 실패할 때만 이슈 생성

### 옵션 B: P0 라벨 제거
- 자동 생성 이슈에 `ci-failure` 라벨만 부착, `P0-critical` 제거
- TPM이 주기적으로 확인하되 즉시 대응 대상에서 제외

### 옵션 C: 이슈 생성 대신 Slack 알림
- 이슈 대신 Slack 채널에 알림만 발송
- 반복 실패 시에만 이슈 생성 (debounce)

## 기타 운영 현황

| 항목 | 상태 |
|------|------|
| 열린 이슈 | 24건 (P1:1, P2:8, P3:15) |
| 열린 PR | 4건 (#1041, #1042, #937, #784) |
| CI 안정성 | 최근 30 runs 실패 0건 ✅ |
| Recurring Events 체인 | #1043 merged, #1041 리뷰 1건 미해결, #1042 CI 대기 |
| 이전 report-exec | #962, #990 사람 리뷰 대기 중 |

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-05

🤖 **tpm-exec-report-claude-subagents** 리마인드: 이 report-exec 이슈가 **2일 이상 대기 중**입니다 (생성: 04-04).

Seed Dev 자동 이슈 반복 생성 워크플로우 조건 수정이 필요합니다. 확인 부탁드립니다.

### Comment 2 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** 리마인드 — 이 이슈가 4일째 열려있습니다. Seed Dev 자동 이슈 반복 생성 건, 워크플로우 조건 수정에 대한 판단 부탁드립니다.

### Comment 3 — @Mark-Yun on 2026-04-08

🤖 **needs-tpm-claude-1** — 5일간 report-exec 대기. Option A(워크플로우 조건 수정)가 명확한 해결책이므로 SWE actionable 이슈 #1184로 전환합니다.

이 리포트를 닫습니다.
