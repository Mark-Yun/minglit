---
source_url: https://github.com/Mark-Yun/minglit/issues/1261
captured_at: 2026-04-10
issue_number: 1261
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #1261 · closed · created 2026-04-10T22:31:35Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1261

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: c7a092dc80668756188e19451521b6d68b203589
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24267090181
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-11

🤖 **tpm-exec-report-claude-subagents** 트리아지.

**근본 원인**: #1238과 동일한 Supabase 인프라 문제로 추정.
- `Seed and Simulate` job에서 `curl exit 22` — `functions/v1/dev-seed` edge function 호출 실패
- #1238에서 확인된 DNS 해석 실패 + pooler 인증 실패와 같은 맥락

**대응**: Supabase 프로젝트 상태 확인 + 시크릿 갱신 필요. `report-exec` 라벨 부착.

### Comment 2 — @github-actions on 2026-04-11

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 2f7470af1c3fa910b192dc52615506bc5e261777
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24292949127
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 3 — @Mark-Yun on 2026-04-12

## Root Cause 분석 완료

### 실패 지점
**"Static seed (users/partners)" 스텝** — `dev-seed?mode=static` Edge Function 호출 시 HTTP 에러 (curl exit code 22).

### 직접 원인: seedAllUsers() API 호출 병목

`seedAllUsers()` (L762-777)이 60명 persona를 순차 처리하며, 이미 존재하는 유저에 대해 **매번 4 API 호출**:

```
1. admin.createUser()           → 실패 ("already registered")
2. admin.listUsers({perPage:1000}) → 67명 전체 fetch
3. Array.find()                  → 이메일 검색  
4. admin.updateUserById()        → password/metadata 보정
```

**60명 x 4 API = ~240 순차 API 호출 → ~180-240초 → EF wall-time(150초) 초과**

### 확인된 사실
- dev DB 유저 총 **67명** (seed 65 + 실사용 2) — 유저 수 자체는 문제 아님
- `listUsers({perPage:1000})`를 유저당 1번 x 60번 = **동일 데이터를 60번 반복 fetch**
- 1명이라도 실패하면 `throw err` (L772)로 **전체 seed 중단**

### 왜 지금까지 안 고쳐졌나
- #1046 (TPM 리포트): 문제 보고 + 3가지 옵션 제시 → 사람 판단 대기
- #976, #1184: **알림 조건만 수정** (skip 시 P0 이슈 안 만들게) → 근본 원인 미수정
- 총 ~20건 P0-critical 이슈가 열렸다 닫힘 반복

### 수정 이슈
**#1272** — listUsers 1회 캐싱 + throw 제거로 API 호출 240→61회(또는 1회) 감소. 예상 응답 시간 180초→30초.

### 영향
이 seed가 실패하면 후속 스텝(backend-simulator, CUJ tests)이 전부 skip → **리그레션 감지 불가**. TPM Cycle 102-113에서 보고된 "CUJ 6일 연속 실패"의 **upstream 원인**이 이것일 가능성 높음.
