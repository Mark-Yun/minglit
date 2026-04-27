---
source_url: https://github.com/Mark-Yun/minglit/issues/1575
captured_at: 2026-04-18
issue_number: 1575
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "Missing env vars after deploy on dev"
---

# Missing env vars after deploy on dev

> Issue #1575 · closed · created 2026-04-18T04:59:35Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1575

## Body

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24597343549

## Comments (14)

### Comment 1 — @github-actions on 2026-04-18

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24601002644

### Comment 2 — @Mark-Yun on 2026-04-18

Edge Function 환경변수 누락 이슈입니다. PORTONE_API_KEY, PORTONE_API_SECRET, PORTONE_V2_API_KEY를 Supabase 대시보드 → Edge Functions → 각 함수의 Secrets 설정에서 추가해야 합니다. 코드 변경으로는 해결 불가 — Supabase 콘솔 설정 필요합니다.

### Comment 3 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 재확인 완료.

코드 변경으로 해결 불가한 이슈입니다. Supabase 대시보드에서 각 Edge Function의 Secrets에 아래 환경변수를 수동 추가해야 합니다:

- `PORTONE_API_KEY`, `PORTONE_API_SECRET` → payment-verify, payment-cancel, user-cancel-order, payment-webhook
- `PORTONE_V2_API_KEY` → settlement-register-transfers, payout-sync, partner-sync, identity-verify, reconciliation-daily

`report-exec`으로 라우팅합니다.

### Comment 4 — @github-actions on 2026-04-19

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24622747806

### Comment 5 — @github-actions on 2026-04-19

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24639512162

### Comment 6 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24643221501

### Comment 7 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24665247733

### Comment 8 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24678054784

### Comment 9 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24678144167

### Comment 10 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24679495713

### Comment 11 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24682347092

### Comment 12 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24692724938

### Comment 13 — @github-actions on 2026-04-20

**Missing EF env vars:**
```
payment-verify: PORTONE_API_KEY, PORTONE_API_SECRET
payment-cancel: PORTONE_API_KEY, PORTONE_API_SECRET
user-cancel-order: PORTONE_API_KEY, PORTONE_API_SECRET
payment-webhook: PORTONE_API_KEY, PORTONE_API_SECRET
settlement-register-transfers: PORTONE_V2_API_KEY
payout-sync: PORTONE_V2_API_KEY
partner-sync: PORTONE_V2_API_KEY
identity-verify: PORTONE_V2_API_KEY
reconciliation-daily: PORTONE_V2_API_KEY
```
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24693729266

### Comment 14 — @Mark-Yun on 2026-04-21

## 근본 원인 + Fix 이슈로 이관

4일간 auto-recreate 되던 원인 확정 — \`supabase-deploy.yml\` 의 EF secret 주입 블록에 **PortOne key 만 누락**.

### 원인
- EF 코드: \`Deno.env.get("PORTONE_API_KEY")\` 등으로 9개 EF 가 PortOne env 읽음 (Vault 아님)
- \`supabase-deploy.yml:66-88\` 에서 OPENAI, SENTRY, AXIOM 등은 \`supabase secrets set\` 으로 주입 중
- PortOne 만 이 리스트에서 빠져있어 EF 환경에 영원히 없음
- \`Verify Edge Function env vars\` step 이 health 엔드포인트로 누락 감지 → 자동 이슈 생성/코멘트

### Fix 진행
#### 완료
- GitHub Actions secrets 등록: \`PORTONE_DEV_API_KEY\`, \`PORTONE_DEV_API_SECRET\`, \`PORTONE_DEV_V2_API_KEY\`, \`PORTONE_DEV_V2_WEBHOOK_SECRET\` (minglit_env/dev/supabase.env 에서 가져와 주입)

#### 이관
- **#1683** 에서 \`supabase-deploy.yml\` 수정으로 자동 주입 블록 추가 추적. dev/main 환경별 분기 + 구체 diff 포함. needs-swe P0.

### Main 환경 주의
dev 는 위 4개 secrets 등록으로 해소되지만, **main 은 \`PORTONE_MAIN_*\` 별도 등록 필요** — PortOne production credentials 입력은 관리자(너)가 해야. #1683 Phase 2 에 명시.

실행 추적은 #1683 으로 이관되므로 본 자동 생성 이슈는 close.
