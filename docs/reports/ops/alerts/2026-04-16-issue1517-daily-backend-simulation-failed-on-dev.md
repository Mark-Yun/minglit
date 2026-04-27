---
source_url: https://github.com/Mark-Yun/minglit/issues/1517
captured_at: 2026-04-16
issue_number: 1517
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #1517 · closed · created 2026-04-16T22:33:27Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1517

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 4cc8e049b7db0bf11c97139d5319f814096f1280
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24537447351
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (2)

### Comment 1 — @github-actions on 2026-04-17

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 414f28d108de2e0f51d9767c152b5989e0cdfa2b
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24589510843
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 2 — @Mark-Yun on 2026-04-18

## 근본 원인 파악 완료 — #1553과 동일 원인으로 병합 처리

이 ci-failure 이슈는 **#1553** 에서 함께 해결됩니다.

### 요약
- 에러: \`psql ... FATAL: (ENOTFOUND) tenant/user postgres.*** not found\` — host \`aws-0-ap-northeast-2.pooler.supabase.com\`
- \`.github/workflows/daily-backend-simulation.yml:29\` 에 pooler host가 옛 \`aws-0\`로 하드코딩됨
- **#1499/#1553과 완전히 동일한 원인** (Supabase pooler 인프라 `aws-0` → `aws-1` 이전 미대응)
- 영향: 2026-04-10부터 매일 scheduled run 10일 연속 실패

### 조치
#1553의 스코프를 `supabase-deploy.yml` + `daily-backend-simulation.yml` 두 파일로 확장했습니다. 하나의 fix(`aws-0` → `aws-1`) + 하드코딩 제거 장기안으로 양쪽 동시 해소됩니다.

실행 추적은 #1553으로 이관되었으므로 이 자동 생성 ci-failure 이슈는 close합니다.
