---
source_url: https://github.com/Mark-Yun/minglit/issues/1373
captured_at: 2026-04-13
issue_number: 1373
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-04-13: Supabase Deploy 10연속 실패 + Dependabot PR 리뷰 대기"
---

# ⚠️ TPM Report — 2026-04-13: Supabase Deploy 10연속 실패 + Dependabot PR 리뷰 대기

> Issue #1373 · closed · created 2026-04-13T00:07:13Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1373

## Body

Scheduler: tpm-exec-report-claude-subagents

## 요약

2가지 사항에 대해 사람 확인이 필요합니다.

---

### 1. Deploy Supabase Migrations 10연속 실패 (P1-high)

**이슈**: #1357

**상황**: 04-12 14:45 이후 모든 `Deploy Supabase Migrations` 실행이 실패 중 (10/10).

**근본 원인**: `supabase functions deploy` 단계에서 Deno import map 해석 실패.
```
Relative import path "@supabase/supabase-js" not prefixed with / or ./ or ../
and not in import map from ".../supabase/functions/_shared/supabase_client.ts"
```

- Import map (`supabase/functions/deno.json`)은 정상 존재
- 워크플로우가 `supabase/setup-cli@v1`의 `version: latest` 사용 → 최신 CLI가 import map 해석 방식을 변경한 것으로 추정

**영향**:
- Edge Function 배포 차단
- #1368 (Daily Backend Simulation) 연쇄 실패 가능
- `db push` (마이그레이션)는 성공 추정 — `functions deploy`에서 실패

**권장 조치**:
- [ ] `version: latest` → 직전 성공 버전으로 pin (`.github/workflows/supabase-deploy.yml` L29)
- [ ] 또는 Supabase CLI changelog 확인 후 import map 형식 업데이트

**판단 요청**: `version: latest` 정책을 pin으로 전환하는 것이 적절한지 확인 부탁드립니다. SWE가 바로 수정 가능하도록 #1357에 needs-swe 라우팅 완료.

---

### 2. Dependabot PR 3건 리뷰 대기

| PR | 내용 | 대기 시간 |
|----|------|----------|
| #1352 | CI actions 3건 업데이트 | ~4h |
| #1351 | landing-user npm 13건 업데이트 | ~4h |
| #1350 | landing-partner npm 11건 업데이트 | ~4h |

모두 `needs-review` 라벨 부착 상태이나 리뷰어 미배정. Merge 여부 또는 리뷰어 배정이 필요합니다.

---

### 운영 지표 (7일 트렌드)

| 지표 | 수치 |
|------|------|
| 이슈 생성 | 145건 |
| 이슈 종료 | 137건 (94.5%) |
| PR 머지 | 104건 |
| 열린 이슈 | 10건 |

**처리 속도 양호.** Integration Test Epic (#1310) 진행으로 높은 처리량 유지.

### 이번 사이클 트리아지 완료

- #1293 종료 (QA+PM 분석 완료)
- #1303, #1304 종료 (일회성 빌드 실패, #1322 수정 완료)
- #1363 → P3-low + needs-uiux (UX 품질 이슈 6건)
- #1357 → P1-high + needs-swe (근본 원인 분석 제공)
- #1368 → P2-medium (#1357 연쇄 영향)

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-13

## 관련 이슈 업데이트

### Supabase Deploy 10연속 실패
이미 진단 완료 + 수정 이슈 존재:
- **#1228** — \`supabase-deploy.yml\` verification 스텝을 pooler 엔드포인트로 전환
- **Root cause**: \`db.{ref}.supabase.co\`의 A(IPv4) 레코드 제거됨 → GitHub runner에서 DNS 해석 불가
- **실제 migration 배포는 정상** — \`supabase db push\`(CLI)는 내부적으로 pooler 사용하므로 성공. verification 스텝만 실패해서 workflow red 표시
- \`supabase migration list --linked\`로 dev DB에 모든 migration 반영 확인됨

### Daily Backend Simulation 실패 (#1368)
- **Root cause**: dev-seed가 560명 유저를 개별 API 호출(createUser × 560)로 생성 → EF wall-time 초과
- **근본 해결**: **#1390** — \`dev_seed_bulk_users\` + \`dev_seed_bulk_partners\` RPC로 전환 (560 HTTP 호출 → 2 RPC, 530초 → 15초)
- #1390이 머지되면 seed 실패 완전 해소
