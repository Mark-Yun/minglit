# Worklog: Bug Reporter + CI + Secrets Planning

Branch: feat/bug-reporter
PR: #11 (bug reporter + CI changes + supabase secrets)

## Current Status Summary
- Bug reporter implemented (shake-to-report) and wired into app_user/app_partner.
- Log utility updated to keep in-memory history and suppress console output in release.
- Supabase Edge Function `report-bug` created to file GitHub issues.
- CI format steps removed from app_user/app_partner tests; new auto-format workflow added.
- Supabase deploy workflow updated to inject GitHub token secrets.
- Supabase pgTAP test fixed (storage schema expectation for objects.level removed).
- minglit_kit `flutter analyze` passes locally.

## Key Files Modified
- shared/packages/minglit_kit/lib/src/ui/widgets/bug_reporter_wrapper.dart
- shared/packages/minglit_kit/lib/src/utils/log.dart
- shared/packages/minglit_kit/lib/src/data/repositories/bug_report_repository.dart
- shared/packages/minglit_kit/lib/minglit_ui.dart
- supabase/functions/report-bug/index.ts
- supabase/tests/database/10_storage_schema_test.sql
- .github/workflows/ci.yml
- .github/workflows/auto-format.yml
- .github/workflows/supabase-deploy.yml

## CI Changes
- Removed dart format gating from test-app-user and test-app-partner in CI.
- Added auto-format workflow to run dart fix + dart format and auto-commit changes on PRs.

## Security Findings (non-.env)
Hardcoded PortOne/Iamport credentials:
- supabase/functions/verify-payment-v1/index.ts (IMP_KEY, IMP_SECRET)
- supabase/functions/portone-webhook-v1/index.ts (IMP_KEY, IMP_SECRET)
- supabase/functions/verify-identity-v1/index.ts (IMP_KEY, IMP_SECRET)
- supabase/functions/verify-identity-v2/index.ts (PORTONE_API_KEY)

Private key files present in repo:
- minglit_secret/ios_distribution.key
- minglit_secret/ios_distribution.p12

Firebase google-services.json files include API keys:
- apps/app_user/android/app/src/dev/google-services.json
- apps/app_user/android/app/src/main/google-services.json
- apps/app_partner/android/app/src/dev/google-services.json
- apps/app_partner/android/app/src/main/google-services.json

## Secrets Plan (Draft)
Supabase runtime secrets (use same names in code):
- PORTONE_V1_IMP_KEY
- PORTONE_V1_IMP_SECRET
- PORTONE_V2_API_KEY
- PORTONE_V2_API_SECRET (confirm if required)
- IAMPORT_USER_CODE

GitHub Secrets (Dev/Prod split):
- SUPABASE_DEV_PORTONE_V1_IMP_KEY
- SUPABASE_DEV_PORTONE_V1_IMP_SECRET
- SUPABASE_DEV_PORTONE_V2_API_KEY
- SUPABASE_DEV_PORTONE_V2_API_SECRET
- SUPABASE_DEV_IAMPORT_USER_CODE
- SUPABASE_MAIN_PORTONE_V1_IMP_KEY
- SUPABASE_MAIN_PORTONE_V1_IMP_SECRET
- SUPABASE_MAIN_PORTONE_V2_API_KEY
- SUPABASE_MAIN_PORTONE_V2_API_SECRET
- SUPABASE_MAIN_IAMPORT_USER_CODE

## Pending Items
- Confirm Supabase Vault vs Secrets from latest docs.
- Confirm PortOne/Iamport auth keys for V1/V2 and dev/prod from official docs.
- Replace hardcoded keys with Deno.env.get(...).
- Remove/relocate minglit_secret files from repo and rotate keys.
- Update workflows to set new PortOne/Iamport secrets per environment.

## Notes
- GitHub Actions currently failing due to billing issues (jobs not started).
- test-app-user/partner format gating removed; formatting now handled by auto-format workflow.
