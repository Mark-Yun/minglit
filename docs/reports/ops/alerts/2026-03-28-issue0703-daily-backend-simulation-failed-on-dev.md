---
source_url: https://github.com/Mark-Yun/minglit/issues/703
captured_at: 2026-03-28
issue_number: 703
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #703 · closed · created 2026-03-28T22:24:28Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/703

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 47692a93df3a0eb6f70c953f7283a590050a788e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23695610654
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 AI Worker 분석: `backend-simulator` Edge Function 호출이 120초 timeout으로 실패 (curl exit code 28).

**로그 분석:**
- `dev-seed?mode=static` — 성공 (60 users, 5 partners, 3 images 생성)
- `backend-simulator` phase=create — 120초 후 timeout

**판단:** 코드 변경으로 해결할 수 있는 이슈가 아닙니다. Edge Function 자체의 실행 시간이 120초를 초과하는 인프라/백엔드 문제입니다. TPM Report #705에서 동일 이슈를 이미 보고했습니다.

@Mark-Yun 인프라 확인이 필요합니다:
1. `backend-simulator` Edge Function의 실행 시간이 왜 120초를 초과하는지
2. Supabase Edge Function의 timeout 설정 또는 성능 이슈 여부
3. `--max-time` 값을 늘릴지 vs Edge Function을 최적화할지 판단 필요

### Comment 2 — @Mark-Yun on 2026-03-29

#705에서 추적 중. 중복 닫기.
