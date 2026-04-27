---
source_url: https://github.com/Mark-Yun/minglit/issues/1238
captured_at: 2026-04-10
issue_number: 1238
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Deploy Supabase Migrations failed on dev"
---

# 🚨 Deploy Supabase Migrations failed on dev

> Issue #1238 · closed · created 2026-04-10T08:36:58Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1238

## Body

**Workflow**: Deploy Supabase Migrations
**Branch**: dev
**Commit**: 8d744814534bb775c37e342aa2f5eff41a89df64
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24234214881
**Triggered by**: fix: prevent event approvals from exceeding capacity (#1220)

Scheduler: needs-swe-codex-1

## Summary
- block single approvals when the event is already full
- limit bulk approvals to the remaining capacity in created-at order
- add regression coverage for full and partial-capacity approval paths

## Testing
- deno test --config supabase/deno.json --allow-all
supabase/functions/partner-approve-application/

Closes #1219

---------

Co-authored-by: needs-swe-sonnet-subagents-1 <worker@minglit.ai>
Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>
**Actor**: Mark-Yun

**Job Results**:
  ❌ deploy: failure

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-10

🤖 **needs-tpm-claude-1** 분석 완료.

**근본 원인: Supabase 인프라/인증 문제 (코드 수정 불가)**

5회 연속 실패 분석:
- 초기 실패 (08:34): `Failed to resolve IPv4 for db.***.supabase.co` — DNS 해석 실패
- 최신 실패 (11:04): `FATAL: Tenant or user not found` — Supabase pooler 인증 실패

**대응 필요:**
1. Supabase 프로젝트 상태 확인 (일시 중지/삭제 여부)
2. GitHub Secrets 의 DB_PASSWORD, PROJECT_ID 유효성 검증
3. Supabase dashboard에서 pooler 설정 확인

코드 수정으로 해결할 수 없는 문제이므로 `report-exec`로 에스컬레이션합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## 진단 결과 — #1228 중복

**migration 배포는 정상 성공했음.** `supabase migration list --linked`로 확인:
- `20260410000003_application_capacity_guard` → dev DB에 반영 완료 ✅

CI가 red로 표시된 건 **Verify vault secrets 스텝**에서 `db.{ref}.supabase.co` IPv4 DNS 해석 실패 때문. 이건 Supabase가 direct DB 호스트의 A(IPv4) 레코드를 제거하고 AAAA(IPv6)만 남긴 변경 때문이며, GitHub Actions runner가 IPv6 outbound를 지원하지 않아 발생.

**실제 배포 경로** (`supabase db push`, `supabase functions deploy`)는 CLI가 내부적으로 pooler 엔드포인트를 사용해서 정상 작동함. verification만 레거시 psql 직접 접속 방식이라 실패.

**수정 이슈**: #1228 (pooler 엔드포인트로 verification 전환)

#1228 해결되면 이 false-positive 실패도 해소됨.
