---
source_url: https://github.com/Mark-Yun/minglit/issues/1443
captured_at: 2026-04-14
issue_number: 1443
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-14: P0 CI 실패 3건 미라우팅 + db-invariant-monitor 워크플로우 오류"
---

# ⚠️ TPM Report — 2026-04-14: P0 CI 실패 3건 미라우팅 + db-invariant-monitor 워크플로우 오류

> Issue #1443 · closed · created 2026-04-14T00:06:30Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1443

## Body

Scheduler: tpm-exec-report-claude-subagents

## 요약

P0-critical CI 실패 이슈 3건이 `needs-swe` 없이 방치되어 있었고, db-invariant-monitor가 워크플로우 파일 오류로 100% 실패 중입니다.

## 1. P0 CI 실패 미라우팅 — 즉시 조치 완료

자동 생성된 ci-failure 이슈에 `needs-swe`가 누락되어 SWE가 인지 못하는 상태였습니다.

| 이슈 | 제목 | 조치 |
|------|------|------|
| #1433 | iOS Deploy Partner failed | `needs-swe` 부착 완료 |
| #1434 | Android Deploy Partner failed | `needs-swe` 부착 완료 |
| #1412 | Daily Backend Simulation failed | `needs-swe` 부착 완료 |

**제안**: CI failure 자동 이슈 생성 워크플로우에 `needs-swe` 라벨을 기본 포함하도록 수정 검토.

## 2. db-invariant-monitor 워크플로우 파일 오류 (신규)

- 최근 3회 연속 실패 (100%)
- 에러: "This run likely failed because of a workflow file issue"
- 데이터 무결성 문제가 아닌 **CI 설정 오류**
- 데이터 무결성 모니터링 사각지대 발생 중

**필요 조치**: `.github/workflows/db-invariant-monitor.yml` 파일 확인 + 수정

## 3. 기존 장애 지속

- **Supabase Deploy Migrations** (#1357): 전일 보고, 아직 미해결. `supabase/setup-cli@v1`의 `version: latest` → 고정 버전 pin 필요.

## 4. audit-report #1440 처리 완료

- actionable 항목 0건 (P2 3건은 PR #1442로 이미 수정, P3 4건은 false positive 또는 기존 커버리지로 충분)
- 원본 리포트 닫음

## 운영 지표 (04-07 ~ 04-14)

| 지표 | 수치 |
|------|------|
| 열린 이슈 | 9건 (전일 10건) |
| CI 전체 성공률 | 안정 워크플로우 정상, 실패: db-invariant(3/3), Deploy Supabase(1/1), Backend Sim(1/1) |
| review-presence | 85% 성공 (전일 62.5%에서 개선) |
| 열린 PR | 1건 (#1439 Axiom 로깅, re-review 대기) |

## 사람 판단 필요

1. db-invariant-monitor 워크플로우 YAML 오류 — SWE에게 워크플로우 수정 지시?
2. CI failure 자동 이슈에 `needs-swe` 기본 포함 정책 — 워크플로우 수정 승인?
3. #1357 Supabase CLI 버전 pin — 어떤 버전으로 고정할지 결정?

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-15

## 점검 결과 (2026-04-15)

### 1. P0 CI 실패 미라우팅 — 처리 완료
- #1412 → ✅ 닫음 (seed.dev.sql 수정 PR #1463)
- #1433, #1434 → needs-swe 부착됨

### 2. db-invariant-monitor — 실제 실패 아님 (ghost run)

**10건 전부 \`event: push\` — cron 실행 0건.**

워크플로우 파일이 push될 때 GitHub Actions가 생성하는 ghost run이 \`jobs: []\`로 즉시 실패 표시됨. 실제 job은 실행된 적 없음.

**RPC 자체는 정상 작동 확인:**
\`\`\`json
{
  "passed": true,
  "checked_at": "2026-04-15T11:34:23Z",
  "violations": []
}
\`\`\`

cron이 실제로 안 돌고 있는 원인: ghost run 누적으로 GitHub가 워크플로우를 broken 취급 → 스케줄 비활성화. 워크플로우 파일 minor 수정 후 re-push하면 cron 재활성화될 것.

### 3. Supabase Deploy — #1228 존재, 미수정
pooler 전환 이슈 이미 있음.

### 4. CI failure에 needs-swe 기본 포함 — 별도 검토

### Comment 2 — @Mark-Yun on 2026-04-15

점검 완료. db-invariant-monitor는 ghost run (실제 실패 아님), RPC 정상 작동 확인. 나머지 항목은 기존 이슈로 트래킹 중.
