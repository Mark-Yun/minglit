---
source_url: https://github.com/Mark-Yun/minglit/issues/1543
captured_at: 2026-04-18
issue_number: 1543
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-18: db-invariant-monitor 100% 실패 지속 + report-exec 7건 적체 + P1 QA 버그 2건"
---

# ⚠️ TPM Report — 2026-04-18: db-invariant-monitor 100% 실패 지속 + report-exec 7건 적체 + P1 QA 버그 2건

> Issue #1543 · closed · created 2026-04-18T00:05:06Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1543

## Body

Scheduler: tpm-exec-report-claude-subagents

## 요약

3가지 사안에 대해 사람 판단이 필요합니다.

---

## 1. db-invariant-monitor 워크플로우 100% 실패 (지속)

**상태**: 04-17 하루에 10+ 연속 실패. 성공 0건.
**이전 보고**: #1443 (04-14, 종료됨) — 같은 문제 보고 후 종료됐으나 여전히 미해결.

**워크플로우**: `.github/workflows/db-invariant-monitor.yml`
- 매 시간 `check_db_invariants()` RPC 호출
- 실패 시 violation 이슈 자동 생성

**추정 원인**:
- `SUPABASE_DEV_URL` / `SUPABASE_DEV_SECRET_KEY` secrets 미설정 또는 만료
- `check_db_invariants()` RPC 함수가 DB에 없음 (migration 누락)
- Supabase 접근 차단

**영향**: DB 정합성 모니터링 완전 사각지대. 데이터 정합성 이슈를 사전 감지 불가.

**제안**:
- A) secrets 확인 후 수정 → 재실행 테스트
- B) RPC 함수 존재 여부 확인 (`\df check_db_invariants`)
- C) 복구 불가 시 워크플로우 비활성화 (`workflow_dispatch` only)

---

## 2. report-exec 이슈 7건 적체 (2~3일)

사람 판단이 필요한 이슈가 누적 중입니다:

| 이슈 | 제목 | 생성일 | 유형 |
|------|------|--------|------|
| #1484 | iOS Deploy User failed | 04-15 | CI (secrets) |
| #1499 | Deploy Supabase Migrations failed | 04-16 | CI |
| #1504 | PM Report (보안 감사 긴급 대응) | 04-16 | PM 리포트 |
| #1506 | Version Bump failed | 04-16 | CI |
| #1509 | iOS Deploy Partner failed | 04-16 | CI (secrets) |
| #1516 | Hourly User Activity failed | 04-16 | CI |
| #1517 | Daily Backend Sim failed | 04-16 | CI |

**패턴**: iOS deploy 2건(#1484, #1509)은 동일 원인(Apple secrets). 나머지 CI 실패도 secrets/환경 관련.

**제안**: iOS secrets + Supabase migration deploy를 일괄 점검하면 5건 해소 가능.

---

## 3. P1 QA 버그 신규 2건

| 이슈 | 제목 | 핵심 |
|------|------|------|
| #1533 | 일반 유저가 파트너 메뉴 접근 가능 | 결제 웹뷰 복귀 시 bottom nav 권한 이슈. 보안 우려. |
| #1535 | 결제 취소 시 무한 로딩 | 결제 CUJ 차단. webview 취소 콜백 미처리. |

이미 `P1-high` + `needs-swe`로 라우팅 완료. 참고용 보고.

---

## 추가 점검 사항

- **#1338** (app_partner 통합테스트): Mark-Yun assigned, 5일간 업데이트 없음
- **#1310** (Epic: Integration Test): P1-high, assignee 없음, 6일간 업데이트 없음
- **열린 PR**: 0건 (전주 4건 → 0건. 리뷰 병목 완전 해소)
- **7일간 PR 머지**: 30건

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-18

## 분석 완료 — 후속 이슈 파일링

본 TPM 리포트의 3개 사안을 분석 후 실행 가능한 needs-swe 이슈로 분해했습니다.

### 1. db-invariant-monitor 100% 실패
→ **#1549** 로 파일링 (P1-high, needs-swe)

- 이슈 본문의 추정(secrets 미설정 / RPC 누락)은 **오진**으로 확인
- 실제 원인: **GitHub Actions workflow registration stale** — `HTTP 422: Workflow does not have 'workflow_dispatch' trigger` 에러가 결정적 증거. GH 캐시된 definition ≠ 현재 dev YAML
- 증거: scheduled/dispatch run 0건, push ghost run만 30건 전부 startup_failure (duration 0s, jobs 0개)
- 해결: 파일 rename으로 GH 재등록 유도

### 2. report-exec 적체 중 #1499 (Deploy Supabase Migrations)
→ **#1553** 으로 파일링 (P1-high, needs-swe)

- PR #1508 이 seed step만 부분 수정. vault 검증 step에 동일 근본 원인 잔존
- 실제 원인: **Supabase pooler host `aws-0` → `aws-1` 이전**에 workflow 미대응. `ENOTFOUND tenant/user` 에러
- 대시보드/CLI ground truth로 확인 완료
- 해결: `aws-0` → `aws-1` 한 줄 수정 + 하드코딩 제거 장기안

### 3. P1 QA 버그 #1533, #1535
본문대로 `P1-high + needs-swe`로 이미 라우팅 완료. 별도 조치 불필요.

### 나머지 CI 적체 (#1484, #1506, #1509, #1516, #1517, #1504)
본 리포트 권고 그대로 — iOS Apple secrets 일괄 점검 + Supabase deploy 복구(#1553) 후 재검증으로 해소 예상.

이 리포트의 역할은 완료되어 close합니다. 실행 추적은 #1549, #1553에서 계속됩니다.
