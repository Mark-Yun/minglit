---
source_url: https://github.com/Mark-Yun/minglit/issues/1516
captured_at: 2026-04-16
issue_number: 1516
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Hourly User Activity failed on dev"
---

# 🚨 Hourly User Activity failed on dev

> Issue #1516 · closed · created 2026-04-16T22:07:43Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1516

## Body

**Workflow**: Hourly User Activity
**Branch**: dev
**Commit**: 4cc8e049b7db0bf11c97139d5319f814096f1280
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24536493928
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-18

## 분석 완료 — 자연 복구 + 영구 fix 대기 중

### 현재 상태
최근 10 run 전부 success (2026-04-17 11:30 UTC ~). symptom은 이미 사라짐. 이 ci-failure 이슈를 close합니다.

### 원인
`backend-simulator` EF의 **tick mode가 `SIM_USER_PASSWORD` 환경변수 미설정으로 즉시 throw** → \`curl\` exit 22 (HTTP 5xx). `hourly-user-activity.yml:20`에서 `{\"mode\":\"tick\"}` POST 호출이 실패한 것.

### 영구 fix (대기 중)
커밋 **`f2032dd3e` (\"fix(ci): SIM_USER_PASSWORD secret 추가 — tick simulator 500 해소\")** 가 \`supabase-deploy.yml\`에 \`supabase secrets set SIM_USER_PASSWORD=...\` 한 줄을 추가하여 deploy 시 자동 주입.

- 현재 브랜치 `fix/deploy-seed-cli`에 존재, **dev 미머지**
- 이 fix가 실제 효과 보려면 **#1553 (pooler host 수정)으로 Deploy Supabase Migrations가 먼저 성공해야 함** — deploy 자체가 깨져있는 동안에는 secret이 EF에 push되지 않음
- 추정: 현재 green 상태는 누군가 Supabase Dashboard에서 수동으로 secret을 추가했거나 EF 재배포로 우연히 기본값이 반영된 것 — 불안정한 상태

### 권장
- 이 이슈는 symptom 해소로 close
- 재발 시 새 이슈 대신 (a) `f2032dd3e` 머지 상태 (b) #1553 fix 머지 상태를 먼저 확인
- 영구 복구는 #1553 + `fix/deploy-seed-cli` PR이 함께 머지될 때 완성
