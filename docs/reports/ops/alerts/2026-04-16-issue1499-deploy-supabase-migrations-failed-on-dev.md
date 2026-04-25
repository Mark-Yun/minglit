---
source_url: https://github.com/Mark-Yun/minglit/issues/1499
captured_at: 2026-04-16
issue_number: 1499
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Deploy Supabase Migrations failed on dev"
---

# 🚨 Deploy Supabase Migrations failed on dev

> Issue #1499 · closed · created 2026-04-16T00:54:17Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1499

## Body

**Workflow**: Deploy Supabase Migrations
**Branch**: dev
**Commit**: ddf2d69deb1c07dbc2842b85a837571a75391fb2
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24486121509
**Triggered by**: fix(security): EF 인가 결함 — requireServiceRole 4개 EF에 추가 (#1494)

Scheduler: needs-swe-sonnet-subagents-1

Closes #1489

ai-embed, ai-extract-tags, settlement-transfer, notification-worker에
requireServiceRole 가드 추가.
기존 테스트 업데이트 + 401 회귀 테스트 8개 추가.

---------

Co-authored-by: CI Trigger <ci-trigger@minglit.internal>
Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>
**Actor**: Mark-Yun

**Job Results**:
  ❌ deploy: failure

## Comments (3)

### Comment 1 — @github-actions on 2026-04-16

**Workflow**: Deploy Supabase Migrations
**Branch**: dev
**Commit**: bb4850ba5ee1ea7418544a57e74c26282e534b95
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24503025782
**Triggered by**: fix(security): event-checkin 서버 측 Ed25519 QR 서명 검증 추가 — 클라이언트 우회 방지 (#1501)

Closes #1491

---------

Co-authored-by: CI Trigger <ci-trigger@minglit.internal>
Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>
Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>
**Actor**: Mark-Yun

**Job Results**:
  ❌ deploy: failure

### Comment 2 — @github-actions on 2026-04-16

**Workflow**: Deploy Supabase Migrations
**Branch**: dev
**Commit**: 78a4957b6e7463c21c3fc3b208e57d3ff2a6d019
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24503986531
**Triggered by**: fix(security): AI EF env var leak + PII scrubbing fix (#1498)

Closes #1493

---------

Co-authored-by: CI Trigger <ci-trigger@minglit.internal>
Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>
Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>
**Actor**: Mark-Yun

**Job Results**:
  ❌ deploy: failure

### Comment 3 — @Mark-Yun on 2026-04-18

## 근본 원인 파악 완료 — 후속 이슈로 추적 전환

이 ci-failure 이슈는 **#1553** 으로 진단 + 수정안을 이관했습니다.

### 요약
- PR #1508 (`4d1112f16 fix(ci): deploy seed를 psql → db push --include-seed`)이 **seed step만** 부분 수정
- 같은 workflow의 **"Verify vault secrets" step**에 동일한 근본 원인(pooler host 하드코딩) 잔존 → 계속 실패
- 실제 원인: Supabase pooler 인프라 이전 `aws-0-ap-northeast-2` → `aws-1-ap-northeast-2`에 workflow 미대응
- 증거: 에러 로그 `ENOTFOUND tenant/user postgres.***`, 대시보드 Connection pooling 표기, `supabase/.temp/pooler-url` CLI 생성 값 모두 `aws-1` 일치

### 해결
`.github/workflows/supabase-deploy.yml:132` 한 줄 수정 + 하드코딩 제거 장기안은 #1553 참고.

실행 추적은 #1553으로 이관되었으므로 이 자동 생성 ci-failure 이슈는 close합니다.
