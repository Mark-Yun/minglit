---
source_url: https://github.com/Mark-Yun/minglit/issues/1091
captured_at: 2026-04-05
issue_number: 1091
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-06: Vercel Deploy 20시간+ cascading 실패 — cron 간격 또는 concurrency 설정 수정 필요"
---

# ⚠️ TPM Report — 2026-04-06: Vercel Deploy 20시간+ cascading 실패 — cron 간격 또는 concurrency 설정 수정 필요

> Issue #1091 · closed · created 2026-04-05T18:35:33Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1091

## Body

Scheduler: tpm-exec-report-claude-subagents

## 상황

Vercel Deploy 워크플로우가 **20시간+** 연속으로 성공하지 못하고 있습니다.

- **마지막 성공**: 2026-04-04 22:36 UTC
- **이후 8건**: cancelled 7건 + hung (in_progress) 1건
- **영향**: 4개 앱 (app_user, app_partner, landing_user, landing_partner) 모두 20시간+ 미배포

## 타임라인

| 시각 (UTC) | 상태 |
|------------|------|
| 04-04 22:36 | ✅ success |
| 04-05 03:15 | ❌ cancelled |
| 04-05 05:46 | ❌ cancelled |
| 04-05 07:15 | ❌ cancelled |
| 04-05 08:52 | ❌ cancelled |
| 04-05 10:40 | ❌ cancelled |
| 04-05 13:09 | ❌ cancelled |
| 04-05 14:39 | ❌ cancelled |
| 04-05 16:42 | ⏳ in_progress (updatedAt 변경 없음 — hung) |

## 근본 원인 분석

`deploy.yml`의 `concurrency.cancel-in-progress: true` + 2시간 cron 간격에서 deploy 시간이 2시간을 초과하면:
1. cron이 새 run을 시작
2. concurrency 설정이 이전 run을 cancel
3. 새 run도 2시간 내 완료 못함
4. 다음 cron이 또 cancel → **무한 cascading**

## 제안 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| **A. cron 간격 4시간으로 확대** | 간단, deploy 완료 시간 확보 | 배포 주기 느려짐 |
| **B. `cancel-in-progress: false`** | 기존 run 보호 | 동시 실행으로 리소스 낭비 가능 |
| **C. deploy 최적화** (병렬→순차, 캐시 등) | 근본 해결 | 조사+구현 시간 필요 |
| **D. 즉시 `workflow_dispatch` 수동 실행** | 즉시 복구 | 임시 조치, 근본 미해결 |

## TPM 의견

**D (즉시 수동 실행)로 당장 복구 + A (cron 4시간)로 근본 수정** 추천.
현재 출시 전 개발 단계에서 2시간 배포 주기는 과도하고, 4시간이면 충분합니다.

## 관찰 기간

C39 (04-05 15:25 UTC)에서 최초 감지 → C40~C42까지 4사이클 연속 미복구.

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-05

🤖 **tpm-exec-report-claude-subagents** C44 업데이트

## Vercel Deploy 부분 복구 확인

04-05 18:53 UTC run 상세 분석 결과, **3/4 job 성공**:

| Job | 상태 | 완료 시각 |
|-----|------|----------|
| deploy-landing_partner | ✅ success | 18:54 |
| deploy-landing_user | ✅ success | 18:56 |
| deploy-app_user | ✅ success | 18:56 |
| **deploy-app_partner** | ⏳ **hung (~1h45m+)** | — |

**변화**:
- cascading cancel 패턴은 해소됨 (concurrency 설정 정상 동작)
- 대부분 배포 복구, **app_partner만 개별 문제**
- app_partner job이 hung되는 원인을 별도로 조사 필요 (Vercel 빌드 타임아웃 또는 리소스 문제 가능성)

**권장 조치**: app_partner 배포 로그를 Vercel 대시보드에서 직접 확인하여 hung 원인 파악

### Comment 2 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** Cycle 54 — 완전 해소 확정

## Vercel Deploy 완전 복구 확인

Cycle 44 부분 복구 이후, 전체 run이 연속 성공으로 전환됨:

| Run | 시각 (UTC) | 결과 |
|-----|-----------|------|
| 1 | 4/5 22:37 | ✅ 성공 |
| 2 | 4/6 03:18 | ✅ 성공 |
| 3 | 4/6 06:01 | ✅ 성공 |

**3회 연속 전체 성공** → cascading 실패 완전 해소 확정.

### 권고

이 이슈는 자연 해소되었으므로 **닫기 가능**합니다.
cron 간격/concurrency 설정 변경은 현재 불필요하나, 재발 시 재검토 가능.

### Comment 3 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** Cycle 55 — 이슈를 닫습니다.

**근거**: Deploy to Vercel이 3연속 성공 (4/5 22:37, 4/6 00:40, 4/6 02:42)으로 완전 복구 확인. cron 간격/concurrency 변경 없이 자연 해소.

추후 재발 시 새 이슈로 추적합니다.
