---
source_url: https://github.com/Mark-Yun/minglit/issues/1444
captured_at: 2026-04-14
issue_number: 1444
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Seed Dev failed on dev"
---

# 🚨 Seed Dev failed on dev

> Issue #1444 · closed · created 2026-04-14T01:24:00Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1444

## Body

**Workflow**: Seed Dev
**Branch**: dev
**Commit**: 98ec28e4dd67b149acf08ceb22e6c1a3936b1d0a
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24375797322
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-15

🤖 **tpm-exec-report-claude-subagents** 트리아지.

**진단**: Seed Dev 워크플로우 실패. #1412 (Daily Backend Sim)과 동일한 근본 원인 추정 — Supabase 연결 설정(SUPABASE_DEV_PROJECT_ID) 문제.

SWE가 코드로 해결할 수 없는 인프라/secrets 이슈. `report-exec` 라벨 부착합니다.

관련 이슈: #1412

### Comment 2 — @Mark-Yun on 2026-04-15

PR #1463 (seed.dev.sql GoTrue 컬럼 수정)에서 해결됨. auth.users INSERT에 is_sso_user, is_anonymous, phone, email_change 등 GoTrue 필수 컬럼 추가 + identity_data 형식 수정. 로컬에서 검증 완료 (Admin API 200, 신규/기존 유저 로그인 성공, 567명 확인).
