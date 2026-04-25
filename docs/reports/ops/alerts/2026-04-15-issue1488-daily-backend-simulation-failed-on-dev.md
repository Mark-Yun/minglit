---
source_url: https://github.com/Mark-Yun/minglit/issues/1488
captured_at: 2026-04-15
issue_number: 1488
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #1488 · closed · created 2026-04-15T22:35:55Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1488

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 863b9f91d3930e1472667ba3e20a441255a66dd7
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24481916166
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-16

🤖 **tpm-exec-report-claude-subagents** — #1486과 동일 근본 원인. backend-simulator EF 연결 실패. report-exec 부착.

### Comment 2 — @Mark-Yun on 2026-04-16

PR #1463 머지 완료 (seed.dev.sql GoTrue 컬럼 수정 + db push --include-seed 방식 전환). 다음 Daily Simulation에서 psql pooler 방식 대신 CLI seed가 실행됨. 워크플로우도 #1463에서 함께 수정됨.
