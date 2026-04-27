---
source_url: https://github.com/Mark-Yun/minglit/issues/1412
captured_at: 2026-04-13
issue_number: 1412
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #1412 · closed · created 2026-04-13T09:01:37Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1412

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 8f07283c155d87324dfbbd8eec5c5e05a33e58d2
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24334897959
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (7)

### Comment 1 — @github-actions on 2026-04-13

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 8f07283c155d87324dfbbd8eec5c5e05a33e58d2
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24335015992
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 2 — @github-actions on 2026-04-13

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 98ec28e4dd67b149acf08ceb22e6c1a3936b1d0a
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24370463706
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 3 — @Mark-Yun on 2026-04-14

🤖 **tpm-exec-report-claude-subagents**: P0-critical CI 실패 미라우팅 발견. `needs-swe` 라벨 부착합니다. Daily Backend Simulation 실패 원인 조사 필요. db-invariant-monitor 워크플로우 파일 오류와 관련 가능성 있음.

### Comment 4 — @Mark-Yun on 2026-04-14

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 5 — @Mark-Yun on 2026-04-14

Scheduler: needs-swe-sonnet-subagents-1

## 진단 결과

**Root cause**: psql 연결 실패 — `SUPABASE_DEV_PROJECT_ID` 가 stale하거나 잘못된 값일 가능성.

```
psql: error: connection to server at "aws-0-ap-northeast-2.pooler.supabase.com", port 5432 failed:
FATAL: Tenant or user not found
```

**타임라인 분석**:
- 2026-04-07: seed-and-simulate ✅ 성공 (curl 방식)
- 2026-04-13 09:01: seed-and-simulate ❌ 실패 (curl `dev-seed?mode=static` → exit code 22 = HTTP 에러)
- 2026-04-13 22:37: PR #1416 머지 후 첫 실행, psql 방식으로 변경 → "Tenant or user not found"

**두 가지 가능성**:
1. Supabase dev 프로젝트가 비활성으로 인해 일시정지됨 (free tier: 1주 비활성 시 pause)
2. `SUPABASE_DEV_PROJECT_ID` secret (마지막 업데이트: 2026-02-24)이 현재 프로젝트 ref와 불일치

`SUPABASE_DEV_DB_PASSWORD`는 2026-03-22에 업데이트됨. 프로젝트 ref는 2026-02-24로 오래됨.

## 필요 조치

1. Supabase 대시보드에서 dev 프로젝트 상태 확인 (일시정지 여부)
2. `SUPABASE_DEV_PROJECT_ID` secret 값이 현재 프로젝트의 ref와 일치하는지 확인
3. 필요 시 secret 업데이트 후 워크플로우 재실행

코드 레벨의 버그가 아닌 인프라/시크릿 설정 문제로 판단됩니다.

`report-exec` 라벨로 변경합니다.

### Comment 6 — @github-actions on 2026-04-14

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 98ec28e4dd67b149acf08ceb22e6c1a3936b1d0a
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24426469946
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 7 — @Mark-Yun on 2026-04-15

이미 진단 완료. dev_seed_bulk_users RPC의 prod guard가 dev DB에서 `current_setting('app.settings.environment')` = NULL이라 차단됨.

**근본 해결**: #1413 (seed.dev.sql로 전환 — RPC 제거, psql 직접 실행). RPC 자체를 없애면 prod guard 문제 원천 해소.

관련: #1390, #1368, #1415
