# Minglit Major Development Sprint

## TL;DR

> **Quick Summary**: Comprehensive sprint covering 4 missions — auth role change for public party browsing, pgTAP DB test migration, CI pipeline hardening, and execution of 11 pending feature tracks. Foundational missions (auth + testing) complete first as safety nets before feature work begins.
> 
> **Deliverables**:
> - Public-access party browsing (no login required for `/`, `/curation`, `/events/:eventId`)
> - pgTAP DB test suite covering all 13 migrations (schema, RLS, triggers, constraints)
> - Edge Function Deno test suite (mocked, no-DB-dependency)
> - Enhanced CI pipeline with DB tests, Edge Function tests, coverage reporting
> - 11 implemented feature tracks (balance system, payments, refunds, settlement, sharing, etc.)
> 
> **Estimated Effort**: XL (4 missions, ~25+ tasks)
> **Parallel Execution**: YES - 7 waves
> **Critical Path**: Task 1 (Auth) → Task 11 (Sharing) → Task 14 (Payment) → Task 15 (Refund) → Task 16 (Settlement)

---

## Context

### Original Request
Plan a major development sprint for the Minglit party/event matching platform monorepo spanning 4 missions: auth role change, DB testing, CI pipeline, and 11 pending feature tracks.

### Interview Summary
**Key Discussions**:
- User explicitly defined which routes are public vs protected
- User wants pgTAP to replace Dart-based DB tests for schema/RLS/trigger verification
- Solo developer — automation is critical survival strategy
- Missions 1+2 must complete before Mission 4 starts
- Existing conductor/tracks/ directory has spec/plan docs for all 11 pending tracks

**Research Findings**:
- app_user `app_router.dart` (L37-43) already implements `protectedPaths` array pattern — extending it is straightforward
- app_partner uses full-lock redirect (all routes require auth) — appropriate for business accounts
- 13 migration files cover 7 domains (core → users → partners → events → commerce → system → social → matching → refunds → storage → notifications → file_management)
- Existing Dart tests in `tests/backend_integration/` cover ~18 test files across party, admission, user, partner, system, infrastructure domains
- 8 Edge Functions exist, 5 already have `*_test.ts` files (cancel_payment, loop_worker, calculator, openai_service, party_serializer)
- CI currently only runs `supabase -v` for backend — no actual test execution
- pgTAP recommended setup: `supabase-test-helpers` for RLS auth context simulation

### Self-Performed Gap Analysis
**Identified Gaps (addressed in plan)**:
- Partner app auth: Should remain full-lock (business-only app) — confirmed by context
- `login?from=` return-URL pattern already exists in app_user — leveraged for protected route redirects
- Existing `*_test.ts` files in Edge Functions need audit — some may be incomplete stubs
- `purchase-history` route currently at `/purchase-history` but protectedPaths uses `/payment` prefix — mismatch needs fix
- DevMap reorganization should group by auth requirement (public/protected) for dev ergonomics
- Track dependencies: Payment → Refund → Settlement is a strict chain
- Track `user_app_home_navigation_20260120` exists in tracks.md but wasn't in user's 11 tracks list — excluded

---

## Work Objectives

### Core Objective
Establish a robust testing and auth foundation, then systematically implement all 11 pending feature tracks to advance Minglit toward launch readiness.

### Concrete Deliverables
- Modified `app_router.dart` with correct `protectedPaths` for public party browsing
- `backend/supabase/tests/` directory with pgTAP SQL test files covering all 13 migrations
- Edge Function Deno test suite with mocked external dependencies
- Enhanced `.github/workflows/ci.yml` with DB test, Edge Function test, and coverage jobs
- 11 feature implementations per existing conductor track specs

### Definition of Done
- [ ] `supabase test db` passes all pgTAP tests locally
- [ ] `deno test --allow-all` passes all Edge Function tests
- [ ] CI pipeline runs DB tests + Edge Function tests + Flutter tests on PR
- [ ] Unauthenticated users can browse `/`, `/curation`, `/events/:eventId` in app_user
- [ ] All 11 tracks pass their acceptance criteria per conductor specs

### Must Have
- Transaction-wrapped pgTAP tests (auto-rollback)
- RLS policy tests using `supabase-test-helpers` auth context simulation
- `login?from=` redirect for protected routes (already implemented, extend coverage)
- CI gates that block PR merge on test failure

### Must NOT Have (Guardrails)
- Do NOT change partner app auth model — partners always require login
- Do NOT add real external API calls in Edge Function tests — mock everything
- Do NOT create separate plans for each mission — this is ONE integrated plan
- Do NOT modify existing Dart integration tests — pgTAP supplements, doesn't replace them for API/storage testing
- Do NOT over-engineer auth — simple `protectedPaths` array extension is sufficient
- Do NOT add tests that require a running Supabase instance for Edge Function unit tests (Deno mocked tests only)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES — Dart tests in `tests/backend_integration/`, some Deno `*_test.ts` files
- **User wants tests**: YES (TDD for DB + Edge Functions, manual verification for Flutter UI changes)
- **Framework**: pgTAP (DB), Deno test (Edge Functions), Flutter test (widgets)

### Automated Verification

**DB Tests**: `supabase test db` — pgTAP tests execute in PostgreSQL, auto-rollback via transaction
**Edge Functions**: `deno test --allow-all backend/supabase/functions/` — mocked unit tests
**Flutter**: `flutter test` per app — existing test runner
**CI**: GitHub Actions — all above automated on PR

### Manual Verification for UI Changes
For Flutter UI tasks, verification uses:
- `flutter run -t lib/dev_main.dart` → DevMap screen navigation
- Browser URL direct access testing for deep link verification
- Screenshot capture via Playwright for visual regression (if available)

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately) — Foundation:
├── Task 1: Auth Role Change (app_user router) [M1]
├── Task 2: pgTAP Infrastructure Setup [M2]
└── Task 3: Edge Function Test Suite [M2/M4-Track10]

Wave 2 (After Wave 1) — Test Coverage:
├── Task 4: pgTAP Schema & Constraint Tests [M2]
├── Task 5: pgTAP RLS Policy Tests [M2]
├── Task 6: pgTAP Trigger & Function Tests [M2]
└── Task 7: Notification Settings UI [M4-Track11]

Wave 3 (After Wave 2) — CI Pipeline:
├── Task 8: CI DB Test Integration [M3]
├── Task 9: CI Edge Function Test Integration [M3]
├── Task 10: CI Coverage & Lint Enhancement [M3]
└── Task 11: Sharing System [M4-Track7]

Wave 4 (After Wave 1) — Core Backend Features:
├── Task 12: Party Balance System [M4-Track1]
├── Task 13: Secure File Management [M4-Track2]
└── Task 14: Party Creation Logic Refactor [M4-Track9]

Wave 5 (After Wave 4) — Payment Chain:
├── Task 15: User Payment & Ticketing Flow [M4-Track3]
└── Task 16: Ticket Recommendation [M4-Track8]

Wave 6 (After Wave 5) — Dependent Features:
├── Task 17: User Refund & Cancellation [M4-Track4]
└── Task 18: Partner Settlement Dashboard [M4-Track5]

Wave 7 (After Wave 3) — iOS CI/CD:
└── Task 19: iOS Build CI/CD [M4-Track6]
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 (Auth) | None | 11, 15 | 2, 3 |
| 2 (pgTAP Setup) | None | 4, 5, 6 | 1, 3 |
| 3 (Edge Fn Tests) | None | 9 | 1, 2 |
| 4 (Schema Tests) | 2 | 8 | 5, 6, 7 |
| 5 (RLS Tests) | 2 | 8 | 4, 6, 7 |
| 6 (Trigger Tests) | 2 | 8 | 4, 5, 7 |
| 7 (Notif Settings) | 2 | None | 4, 5, 6 |
| 8 (CI DB) | 4, 5, 6 | 19 | 9, 10, 11 |
| 9 (CI Edge Fn) | 3 | 19 | 8, 10, 11 |
| 10 (CI Lint) | None (soft: 8, 9) | 19 | 8, 9, 11 |
| 11 (Sharing) | 1 | None | 8, 9, 10 |
| 12 (Balance) | 1 | 14, 16 | 13, 14 |
| 13 (File Mgmt) | None | None | 12, 14 |
| 14 (Party Refactor) | 12 | 15 | 13 |
| 15 (Payment) | 1, 14 | 17 | 16 |
| 16 (Ticket Rec) | 12 | None | 15 |
| 17 (Refund) | 15 | 18 | None |
| 18 (Settlement) | 17 | None | None |
| 19 (iOS CI/CD) | 8, 9 | None | None |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 1 | 1, 2, 3 | 3x parallel: quick(1), ultrabrain(2), ultrabrain(3) |
| 2 | 4, 5, 6, 7 | 4x parallel: ultrabrain(4,5,6), visual-engineering(7) |
| 3 | 8, 9, 10, 11 | 4x parallel: ultrabrain(8,9,10), visual-engineering(11) |
| 4 | 12, 13, 14 | 3x parallel: ultrabrain(12,14), quick(13) |
| 5 | 15, 16 | 2x parallel: visual-engineering(15), ultrabrain(16) |
| 6 | 17, 18 | sequential: visual-engineering(17) → visual-engineering(18) |
| 7 | 19 | 1x: ultrabrain(19) |

---

## TODOs

---

### MISSION 1: Auth/Login 역할 변경

---

- [ ] 1. Auth Role Change — app_user GoRouter Public/Protected Route Split

  **What to do**:
  - Modify `apps/app_user/lib/src/routing/app_router.dart` redirect logic
  - Update `protectedPaths` array to include ALL routes requiring login:
    ```
    const protectedPaths = [
      '/my',
      '/tickets/my',
      '/payment',
      '/purchase-history',
      '/certification',
    ];
    ```
  - Ensure `/events/:eventId/apply` is also protected — add `/events/` + `/apply` pattern or explicit check
  - Verify these routes remain PUBLIC (no redirect): `/`, `/curation`, `/events/:eventId` (view only), `/dev`, `/dev/switch`, `/login`, `/auth/callback`
  - Update `LoginRoute` to accept and use `from` query parameter for return-after-login (already partially implemented at L41-47 of app_routes.dart)
  - Verify deep link access: enter `/events/some-uuid` directly in browser URL bar → should render without login
  - Reorganize `UserDevMap` (`apps/app_user/lib/src/features/dev/user_dev_map.dart`) to group items by auth requirement:
    - Category "Public" for home, curation, event detail
    - Category "Protected (Login Required)" for my page, purchase history, certification, apply
  - Verify partner app (`apps/app_partner/lib/src/routing/app_router.dart`) remains fully locked — document decision, no code change needed
  - Run `flutter analyze` and `flutter test` for app_user after changes

  **Must NOT do**:
  - Do NOT change partner app auth model
  - Do NOT add complex auth middleware — simple `protectedPaths` array is sufficient
  - Do NOT change the `refreshListenable` or `authStateChangesProvider` logic
  - Do NOT add new packages or dependencies

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small-scoped change to 2-3 files, straightforward logic modification
  - **Skills**: [`git-master`]
    - `git-master`: Clean atomic commit for auth change
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: No visual design work needed
    - `playwright`: Deep link testing can be done via `flutter run` in Chrome

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Tasks 11 (Sharing needs public event URLs), 15 (Payment needs auth gate on /apply)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `apps/app_user/lib/src/routing/app_router.dart:25-52` — Current redirect logic with `protectedPaths` array and `login?from=` pattern
  - `apps/app_partner/lib/src/routing/app_router.dart:28-44` — Partner full-lock pattern (do NOT modify, reference only)

  **API/Type References**:
  - `apps/app_user/lib/src/routing/app_routes.dart:39-48` — `LoginRoute` already accepts `from` parameter
  - `apps/app_user/lib/src/routing/app_routes.dart:97-106` — `EventDetailRoute` with `eventId` param
  - `apps/app_user/lib/src/routing/app_routes.dart:122-132` — `EventApplicationRoute` with `eventId` (must be protected)

  **Test References**:
  - None existing for router redirect logic — verify manually via `flutter run -t lib/dev_main.dart` in Chrome

  **Documentation References**:
  - `apps/app_user/README.md` — Current routing documentation

  **DevMap References**:
  - `apps/app_user/lib/src/features/dev/user_dev_map.dart:6-122` — Full DevMap widget with all screen items

  **Acceptance Criteria**:

  ```bash
  # Agent runs flutter analyze:
  flutter analyze
  # Assert: No errors in apps/app_user/

  # Agent runs flutter test:
  flutter test
  # Assert: All existing tests pass (working-directory: apps/app_user)
  ```

  **Manual Deep Link Verification (via browser)**:
  ```
  1. Start: flutter run -t lib/dev_main.dart -d chrome (working-directory: apps/app_user)
  2. Navigate to: http://localhost:PORT/events/test-event-id (no login)
     → Assert: Page renders event detail (or 404 for invalid ID), NOT login redirect
  3. Navigate to: http://localhost:PORT/ (no login)
     → Assert: Home page renders, NOT login redirect
  4. Navigate to: http://localhost:PORT/curation (no login)
     → Assert: Curation page renders
  5. Navigate to: http://localhost:PORT/my (no login)
     → Assert: Redirected to /login?from=%2Fmy
  6. Navigate to: http://localhost:PORT/events/test-id/apply (no login)
     → Assert: Redirected to /login
  ```

  **Commit**: YES
  - Message: `feat(auth): allow unauthenticated access to party browsing routes`
  - Files: `apps/app_user/lib/src/routing/app_router.dart`, `apps/app_user/lib/src/features/dev/user_dev_map.dart`
  - Pre-commit: `flutter analyze && flutter test` (working-directory: apps/app_user)

---

### MISSION 2: DB Unit Test 강화

---

- [ ] 2. pgTAP Infrastructure Setup — Extension, Helpers, Directory Structure

  **What to do**:
  - Enable pgTAP extension in Supabase config if not already enabled
  - Install `basejump-supabase_test_helpers` via dbdev or SQL migration for test utilities (`create_supabase_user`, `authenticate_as`, `clear_authentication`, `rls_enabled`)
  - Create directory structure: `backend/supabase/tests/database/`
  - Create a bootstrap/setup SQL file that installs test helpers
  - Create a "hello world" pgTAP test to verify infrastructure:
    ```sql
    BEGIN;
    SELECT plan(1);
    SELECT has_table('profiles', 'profiles table exists');
    SELECT * FROM finish();
    ROLLBACK;
    ```
  - Run `supabase test db` locally and verify it passes
  - Document the test helper installation process

  **Must NOT do**:
  - Do NOT modify existing migration files
  - Do NOT add test helper installation to production migrations
  - Do NOT delete existing Dart integration tests

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Database infrastructure setup requiring PostgreSQL + pgTAP expertise
  - **Skills**: [`git-master`]
    - `git-master`: Atomic commit for infra setup
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: No UI work
    - `playwright`: No browser work

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Tasks 4, 5, 6 (all pgTAP test writing depends on infrastructure)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `tests/backend_integration/src/utils/test_database.dart` — Existing Dart test helpers, understand what patterns to replicate in SQL
  - `tests/backend_integration/src/utils/test_helpers.dart` — Test utility patterns
  - `tests/backend_integration/src/system/schema_health_test.dart` — Schema verification patterns to migrate

  **Documentation References**:
  - `conductor/tracks/backend_pg_tap_migration_20260120/spec.md` — Full spec for pgTAP migration
  - `conductor/tracks/backend_pg_tap_migration_20260120/plan.md` — Existing plan details

  **External References**:
  - Official: Supabase pgTAP docs — `supabase.com/docs/guides/database/extensions/pgtap`
  - Helper lib: `github.com/usebasejump/supabase-test-helpers` — Auth context simulation utilities
  - Supabase CLI: `supabase test db` command docs

  **Migration File References** (the 13 files to eventually cover):
  - `backend/supabase/migrations/20260117160000_01_core.sql`
  - `backend/supabase/migrations/20260117160001_02_users.sql`
  - `backend/supabase/migrations/20260117160002_03_partners.sql`
  - `backend/supabase/migrations/20260117160003_04_events.sql`
  - `backend/supabase/migrations/20260117160004_05_commerce.sql`
  - `backend/supabase/migrations/20260117160005_06_system.sql`
  - `backend/supabase/migrations/20260118000000_07_social.sql`
  - `backend/supabase/migrations/20260118000001_08_matching.sql`
  - `backend/supabase/migrations/20260118000002_09_refund_trigger.sql`
  - `backend/supabase/migrations/20260118000003_10_storage_buckets.sql`
  - `backend/supabase/migrations/20260119184500_11_notifications.sql`
  - `backend/supabase/migrations/20260119192000_12_event_notification_trigger.sql`
  - `backend/supabase/migrations/20260119200000_13_file_management.sql`

  **Acceptance Criteria**:

  ```bash
  # Agent runs (working-directory: backend):
  supabase test db
  # Assert: Exit code 0, "1 test passed" (hello world test)

  # Agent verifies directory structure:
  ls backend/supabase/tests/database/
  # Assert: At least 1 .sql file exists
  ```

  **Commit**: YES
  - Message: `feat(db): set up pgTAP infrastructure with test helpers`
  - Files: `backend/supabase/tests/database/*.sql`, config files
  - Pre-commit: `supabase test db` (working-directory: backend)

---

- [ ] 3. Edge Function Deno Test Suite — Mocked Unit Tests for All 8 Functions

  **What to do**:
  - Audit existing test files: `cancel_payment_test.ts`, `loop_worker_test.ts`, `calculator_test.ts`, `openai_service_test.ts`, `party_serializer_test.ts` — assess completeness
  - Create missing test files for functions without tests:
    - `portone-webhook-v1/portone_webhook_test.ts`
    - `verify-identity-v1/verify_identity_v1_test.ts`
    - `verify-identity-v2/verify_identity_v2_test.ts`
    - `verify-payment-v1/verify_payment_test.ts`
  - Create shared test utilities: `backend/supabase/functions/_test_utils/` with:
    - Supabase client mock
    - HTTP request/response mocks
    - Common test fixtures (mock payment data, mock user data)
  - Each test file must cover:
    - Happy path (valid input → expected output)
    - Error cases (invalid params, auth failure, external API failure)
  - All tests must be DB-independent (mocked Supabase client)
  - All external API calls (Iamport, FCM, OpenAI) must be mocked
  - Run `deno test --allow-all` and verify all pass

  **Must NOT do**:
  - Do NOT make real API calls to Iamport/FCM/OpenAI in tests
  - Do NOT require running Supabase instance for unit tests
  - Do NOT modify existing function implementation code
  - Do NOT add integration tests here (that's separate from unit tests)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Deno/TypeScript testing with mocking patterns requires deep technical knowledge
  - **Skills**: [`git-master`]
    - `git-master`: Atomic commit
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: No UI work
    - `playwright`: No browser work

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Task 9 (CI Edge Function integration)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `backend/supabase/functions/cancel-payment/cancel_payment_test.ts` — Existing test pattern
  - `backend/supabase/functions/notification-worker/loop_worker_test.ts` — Worker test pattern
  - `backend/supabase/functions/update-user-profile/calculator_test.ts` — Calculator test pattern
  - `backend/supabase/functions/vectorize-party/openai_service_test.ts` — External API mocking pattern
  - `backend/supabase/functions/vectorize-party/party_serializer_test.ts` — Serializer test pattern

  **API/Type References**:
  - `backend/supabase/functions/_shared/iamport_client.ts` — Shared Iamport client to mock
  - `backend/supabase/functions/_shared/worker_utils.ts` — Shared worker utilities

  **Implementation References (functions to test)**:
  - `backend/supabase/functions/verify-payment-v1/index.ts` — Payment verification logic
  - `backend/supabase/functions/portone-webhook-v1/index.ts` — Webhook handler logic
  - `backend/supabase/functions/verify-identity-v1/index.ts` — Identity verification V1
  - `backend/supabase/functions/verify-identity-v2/index.ts` — Identity verification V2
  - `backend/supabase/functions/notification-worker/index.ts` — Notification worker
  - `backend/supabase/functions/vector-worker/index.ts` — Vector embedding worker

  **Documentation References**:
  - `conductor/tracks/backend_supabase_functions_test_20260120/spec.md` — Full spec

  **External References**:
  - Deno testing: `docs.deno.com/runtime/fundamentals/testing/`
  - Deno mocking: `jsr.io/@std/testing/doc/mock`

  **Acceptance Criteria**:

  ```bash
  # Agent runs (working-directory: backend/supabase):
  deno test --allow-all functions/
  # Assert: Exit code 0, all tests pass

  # Agent verifies test file count:
  find backend/supabase/functions -name "*_test.ts" | wc -l
  # Assert: >= 8 test files (at least one per function)
  ```

  **Commit**: YES
  - Message: `test(functions): add comprehensive Deno unit tests for all Edge Functions`
  - Files: `backend/supabase/functions/**/*_test.ts`, `backend/supabase/functions/_test_utils/`
  - Pre-commit: `deno test --allow-all functions/` (working-directory: backend/supabase)

---

- [ ] 4. pgTAP Schema & Constraint Tests — Tables, Columns, Indexes, Enums, FKs

  **What to do**:
  - Create test files per domain, covering all 13 migrations:
    - `01_core_schema_test.sql` — extensions, shared types
    - `02_users_schema_test.sql` — profiles, user settings
    - `03_partners_schema_test.sql` — partners, partner_members, permissions
    - `04_events_schema_test.sql` — parties, tickets, entry_groups
    - `05_commerce_schema_test.sql` — event_applications, payments
    - `06_system_schema_test.sql` — system tables
    - `07_social_schema_test.sql` — social graph tables
    - `08_matching_schema_test.sql` — matching tables
    - `10_storage_schema_test.sql` — storage buckets config
    - `11_notifications_schema_test.sql` — notification tables
    - `13_file_management_schema_test.sql` — file management tables
  - Test coverage per file:
    - `has_table()` for all tables
    - `has_column()` for critical columns
    - `col_type_is()` for type verification (especially enums, JSONB, UUID, timestamptz)
    - `col_is_pk()` for primary keys
    - `col_is_fk()` for foreign key relationships
    - `has_index()` for performance-critical indexes
    - `col_not_null()` for NOT NULL constraints
    - `col_has_default()` for default values (e.g., `now()`, `gen_random_uuid()`)

  **Must NOT do**:
  - Do NOT test data content — only structure
  - Do NOT duplicate RLS tests (Task 5) or trigger tests (Task 6)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Requires reading 13 migration files and generating comprehensive pgTAP SQL assertions
  - **Skills**: [`git-master`]
  - **Skills Evaluated but Omitted**:
    - All non-backend skills irrelevant

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7)
  - **Blocks**: Task 8 (CI DB integration)
  - **Blocked By**: Task 2 (pgTAP infrastructure)

  **References**:

  **Pattern References**:
  - `tests/backend_integration/src/system/schema_health_test.dart` — Existing schema validation patterns to replicate in SQL

  **Source References (migrations to read and test)**:
  - `backend/supabase/migrations/20260117160000_01_core.sql` through `20260119200000_13_file_management.sql` — ALL 13 files

  **External References**:
  - pgTAP table/column functions: `pgtap.org/documentation.html`

  **Acceptance Criteria**:

  ```bash
  # Agent runs:
  supabase test db
  # Assert: All schema tests pass
  # Assert: >= 100 individual test assertions across all schema files
  ```

  **Commit**: YES
  - Message: `test(db): add pgTAP schema and constraint tests for all 13 migrations`
  - Files: `backend/supabase/tests/database/*_schema_test.sql`
  - Pre-commit: `supabase test db` (working-directory: backend)

---

- [ ] 5. pgTAP RLS Policy Tests — Row Level Security Verification per Role

  **What to do**:
  - Create RLS test files per domain:
    - `02_users_rls_test.sql` — Profile visibility and update restrictions
    - `03_partners_rls_test.sql` — Partner data isolation, member permissions
    - `04_events_rls_test.sql` — Party visibility (public read), application privacy
    - `05_commerce_rls_test.sql` — Payment/ticket data owner-only access
    - `11_notifications_rls_test.sql` — Notification recipient-only access
    - `13_file_management_rls_test.sql` — File access controls
  - For each domain:
    - Use `tests.create_supabase_user()` to create test users with different roles
    - Use `tests.authenticate_as()` to simulate authenticated requests
    - Use `tests.clear_authentication()` to simulate anonymous requests
    - Test: anonymous cannot access protected data
    - Test: authenticated user can only access own data
    - Test: partner can access their own venue/party data
    - Test: cross-user data isolation (user A cannot see user B's tickets)
  - Verify `rls_enabled('public')` for all tables with sensitive data

  **Must NOT do**:
  - Do NOT test schema structure (Task 4)
  - Do NOT test trigger behavior (Task 6)
  - Do NOT use real Supabase auth — use test helper auth simulation

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Security-critical testing requiring deep RLS policy understanding
  - **Skills**: [`git-master`]
  - **Skills Evaluated but Omitted**:
    - All non-backend skills irrelevant

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6, 7)
  - **Blocks**: Task 8 (CI DB integration)
  - **Blocked By**: Task 2 (pgTAP infrastructure with test helpers)

  **References**:

  **Pattern References**:
  - `tests/backend_integration/src/party/party_rls_test.dart` — Existing RLS test patterns in Dart
  - `tests/backend_integration/src/admission/application_rls_test.dart` — Application RLS patterns
  - `tests/backend_integration/src/user/profile_rls_test.dart` — Profile RLS patterns
  - `tests/backend_integration/src/partner/permission_policy_test.dart` — Partner permission patterns
  - `tests/backend_integration/src/infrastructure/storage_policy_test.dart` — Storage RLS patterns

  **Source References**:
  - All 13 migration files — specifically `CREATE POLICY` statements and `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`

  **External References**:
  - basejump/supabase-test-helpers: `github.com/usebasejump/supabase-test-helpers` — `authenticate_as`, `clear_authentication`

  **Acceptance Criteria**:

  ```bash
  # Agent runs:
  supabase test db
  # Assert: All RLS tests pass
  # Assert: Tests cover at least: anon access, owner access, cross-user isolation per domain
  ```

  **Commit**: YES
  - Message: `test(db): add pgTAP RLS policy tests for all domains`
  - Files: `backend/supabase/tests/database/*_rls_test.sql`
  - Pre-commit: `supabase test db` (working-directory: backend)

---

- [ ] 6. pgTAP Trigger & Function Tests — Refund, Notification, updated_at, Auto-Approval

  **What to do**:
  - Create trigger/function test files:
    - `09_refund_trigger_test.sql` — Refund trigger logic verification
    - `12_event_notification_trigger_test.sql` — Event update → notification creation trigger
    - `general_trigger_test.sql` — `updated_at` auto-update triggers across tables
    - `auto_approval_trigger_test.sql` — Auto-approval logic for applications
    - `capacity_sync_test.sql` — Party capacity synchronization triggers
  - For each trigger:
    - Set up test data within transaction
    - Perform the action that fires the trigger
    - Verify the expected side effect occurred
    - Test edge cases (e.g., refund on already-cancelled, notification on deleted event)
  - For RPC functions:
    - Test any PL/pgSQL functions defined in migrations
    - Verify correct return types and values

  **Must NOT do**:
  - Do NOT test schema structure (Task 4) or RLS policies (Task 5)
  - Do NOT test Edge Function logic (that's Task 3)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Complex trigger behavior testing requiring PostgreSQL expertise
  - **Skills**: [`git-master`]
  - **Skills Evaluated but Omitted**:
    - All non-backend skills irrelevant

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 7)
  - **Blocks**: Task 8 (CI DB integration)
  - **Blocked By**: Task 2 (pgTAP infrastructure)

  **References**:

  **Pattern References**:
  - `tests/backend_integration/src/admission/refund_trigger_test.dart` — Existing refund trigger test pattern
  - `tests/backend_integration/src/admission/auto_approval_trigger_test.dart` — Auto-approval pattern
  - `tests/backend_integration/src/party/capacity_sync_test.dart` — Capacity sync pattern
  - `tests/backend_integration/src/notification/notification_repository_test.dart` — Notification patterns
  - `tests/backend_integration/src/user/action_trigger_test.dart` — User action trigger patterns

  **Source References**:
  - `backend/supabase/migrations/20260118000002_09_refund_trigger.sql` — Refund trigger definition
  - `backend/supabase/migrations/20260119192000_12_event_notification_trigger.sql` — Event notification trigger

  **Acceptance Criteria**:

  ```bash
  # Agent runs:
  supabase test db
  # Assert: All trigger/function tests pass
  # Assert: Refund trigger correctly processes cancellation
  # Assert: Notification trigger creates notification records on event update
  ```

  **Commit**: YES
  - Message: `test(db): add pgTAP trigger and function tests`
  - Files: `backend/supabase/tests/database/*_trigger_test.sql`
  - Pre-commit: `supabase test db` (working-directory: backend)

---

### MISSION 3: CI 검증 파이프라인 강화

---

- [ ] 7. User App Notification Settings UI (M4-Track 11)

  **What to do**:
  - Implement the notification settings screen per existing spec
  - Follow existing conductor track spec: `conductor/tracks/user_app_notification_settings_20260120/`
  - Read the spec.md and plan.md in that directory for full requirements
  - Implement the `NotificationSettingsScreen` widget (route already defined at `apps/app_user/lib/src/routing/app_routes.dart:147-155`)
  - Follow existing UI patterns from `minglit_kit` design system
  - Add to DevMap under "Settings" category

  **Must NOT do**:
  - Do NOT implement push notification backend logic (already done in unified notification system track)
  - Do NOT change the notification data model

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI implementation following design system
  - **Skills**: [`frontend-ui-ux`, `git-master`]
    - `frontend-ui-ux`: Flutter widget implementation with design system
    - `git-master`: Atomic commit

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6)
  - **Blocks**: None
  - **Blocked By**: None (can technically start Wave 1, placed in Wave 2 for resource management)

  **References**:

  **Documentation References**:
  - `conductor/tracks/user_app_notification_settings_20260120/spec.md` — Full specification
  - `conductor/tracks/user_app_notification_settings_20260120/plan.md` — Implementation plan

  **Pattern References**:
  - `apps/app_user/lib/src/features/home/my_page_screen.dart` — Similar settings-style screen pattern
  - `apps/app_user/lib/src/routing/app_routes.dart:147-155` — Route already defined (`NotificationSettingsRoute`)

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors (working-directory: apps/app_user)

  flutter test
  # Assert: All tests pass (working-directory: apps/app_user)
  ```

  **Manual Verification**:
  ```
  1. flutter run -t lib/dev_main.dart -d chrome (working-directory: apps/app_user)
  2. Navigate to /my/notification-settings via DevMap or URL
  3. Assert: Settings screen renders with toggle controls
  ```

  **Commit**: YES
  - Message: `feat(user): implement notification settings screen`
  - Files: `apps/app_user/lib/src/features/*/notification*`
  - Pre-commit: `flutter analyze && flutter test` (working-directory: apps/app_user)

---

- [ ] 8. CI Pipeline — DB Test Integration with pgTAP

  **What to do**:
  - Modify `.github/workflows/ci.yml` to enhance the `check-supabase` job:
    - Add `supabase start` step (starts local Supabase with all migrations applied)
    - Add `supabase test db` step to run all pgTAP tests
    - Add `supabase db lint` step for SQL quality checks
    - Ensure the job fails the PR if any test fails
  - Add proper caching for Supabase Docker images to speed up CI
  - Add timeout configuration (Supabase start can be slow)

  **Must NOT do**:
  - Do NOT remove existing CI jobs
  - Do NOT change path-filter logic for other apps
  - Do NOT add secrets or environment variables that don't already exist

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: CI/CD pipeline configuration requiring GitHub Actions expertise
  - **Skills**: [`git-master`]
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: No UI work
    - `playwright`: No browser work

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11)
  - **Blocks**: Task 19 (iOS CI depends on stable CI foundation)
  - **Blocked By**: Tasks 4, 5, 6 (need pgTAP tests to exist before adding to CI)

  **References**:

  **Pattern References**:
  - `.github/workflows/ci.yml:116-125` — Current `check-supabase` job (minimal, only runs `supabase -v`)

  **External References**:
  - `supabase/setup-cli@v1` — GitHub Action for Supabase CLI
  - Supabase CI docs: `supabase.com/docs/guides/deployment/ci/testing`
  - basejump CI example: `github.com/usebasejump/basejump/blob/main/.github/workflows/tests.yml`

  **Acceptance Criteria**:

  ```bash
  # Agent reads the updated ci.yml and verifies:
  grep -c "supabase start" .github/workflows/ci.yml
  # Assert: >= 1

  grep -c "supabase test db" .github/workflows/ci.yml
  # Assert: >= 1

  grep -c "supabase db lint" .github/workflows/ci.yml
  # Assert: >= 1
  ```

  **Commit**: YES
  - Message: `ci: add pgTAP database tests to CI pipeline`
  - Files: `.github/workflows/ci.yml`
  - Pre-commit: `yamllint .github/workflows/ci.yml` (if available) or manual review

---

- [ ] 9. CI Pipeline — Edge Function Test Integration

  **What to do**:
  - Add a new job to `.github/workflows/ci.yml` for Edge Function tests:
    - Trigger on `supabase` path filter (already exists)
    - Install Deno via `denoland/setup-deno@v2`
    - Run `deno test --allow-all backend/supabase/functions/`
    - Run `deno lint backend/supabase/functions/` for code quality
  - Alternatively, add Deno steps to existing `check-supabase` job
  - Ensure test failures block PR merge

  **Must NOT do**:
  - Do NOT require running Supabase for Edge Function unit tests (they're mocked)
  - Do NOT add integration tests to CI (keep CI fast)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: CI/CD configuration for Deno test runner
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 10, 11)
  - **Blocks**: Task 19 (iOS CI)
  - **Blocked By**: Task 3 (Edge Function tests must exist)

  **References**:

  **Pattern References**:
  - `.github/workflows/ci.yml:116-125` — Current `check-supabase` job

  **External References**:
  - `denoland/setup-deno@v2` — GitHub Action for Deno
  - Supabase Edge Function testing CI: `supabase.com/docs/guides/deployment/ci/testing`

  **Acceptance Criteria**:

  ```bash
  grep -c "deno test" .github/workflows/ci.yml
  # Assert: >= 1

  grep -c "setup-deno" .github/workflows/ci.yml
  # Assert: >= 1
  ```

  **Commit**: YES (group with Task 8 if done by same agent)
  - Message: `ci: add Edge Function Deno tests to CI pipeline`
  - Files: `.github/workflows/ci.yml`

---

- [ ] 10. CI Pipeline — Coverage Reporting & Lint Enhancement

  **What to do**:
  - Add Flutter test coverage reporting to `test-app-user` and `test-app-partner` jobs:
    - `flutter test --coverage`
    - Upload coverage report as artifact or use `codecov/codecov-action`
  - Add `flutter format --set-exit-if-changed .` to Flutter CI jobs for format enforcement
  - Add `dart fix --dry-run` to detect fixable issues
  - Consider adding a PR status check that aggregates all job results
  - Add `npm run build` to landing app CI jobs (currently only lint, no build check)

  **Must NOT do**:
  - Do NOT set minimum coverage thresholds yet (establish baseline first)
  - Do NOT add paid CI services
  - Do NOT break existing CI jobs

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: CI/CD enhancement with coverage tooling
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 11)
  - **Blocks**: Task 19 (iOS CI)
  - **Blocked By**: None (soft dependency on 8, 9 for pipeline coherence)

  **References**:

  **Pattern References**:
  - `.github/workflows/ci.yml:43-59` — Current `test-app-user` job
  - `.github/workflows/ci.yml:62-77` — Current `test-app-partner` job
  - `.github/workflows/ci.yml:80-95` — Current `lint-landing-user` job

  **Acceptance Criteria**:

  ```bash
  grep -c "coverage" .github/workflows/ci.yml
  # Assert: >= 1

  grep -c "format" .github/workflows/ci.yml
  # Assert: >= 1
  ```

  **Commit**: YES
  - Message: `ci: add coverage reporting and format/lint enforcement`
  - Files: `.github/workflows/ci.yml`

---

### MISSION 4: 제미나이 미완료 트랙 실행

---

- [ ] 11. Sharing System — Dynamic Links + OS Share Sheet (M4-Track 7)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/sharing_system_20260118/`
  - Add share button to `EventDetailScreen`
  - Generate shareable deep links (leverages Mission 1 public route access)
  - Integrate `share_plus` package for OS share sheet
  - Deep link should resolve to `/events/:eventId` — which is now publicly accessible (Task 1)

  **Must NOT do**:
  - Do NOT implement Kakao SDK direct sharing (out of scope per spec)
  - Do NOT add sharing to partner app

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI integration + deep link logic
  - **Skills**: [`frontend-ui-ux`, `git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 10)
  - **Blocks**: None
  - **Blocked By**: Task 1 (public routes must be in place for shared links to work)

  **References**:

  **Documentation References**:
  - `conductor/tracks/sharing_system_20260118/spec.md` — Full specification
  - `conductor/tracks/sharing_system_20260118/plan.md` — Implementation plan

  **Pattern References**:
  - `apps/app_user/lib/src/features/event/detail/event_detail_screen.dart` — Target screen for share button
  - `apps/app_user/lib/src/routing/app_routes.dart:97-106` — EventDetailRoute definition

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors (working-directory: apps/app_user)
  ```

  **Commit**: YES
  - Message: `feat(user): implement sharing system with dynamic links`

---

- [ ] 12. Party Balance System — Gender/Group Balance Auto-Management (M4-Track 1)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/party_balance_system_20260117/`
  - Add `balance_config` JSONB column to `parties` table (new migration)
  - Implement balance check RPC function in PostgreSQL
  - Add partner app UI: "성비 균형 자동 관리" toggle switch in party creation/edit
  - Add user app UI: "일시 품절" display when balance limit hit
  - Implement waitlist notification when balance unlocks

  **Must NOT do**:
  - Do NOT implement age-based grouping (future enhancement per spec)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Complex backend logic (transaction-level balance checking) + both app UI changes
  - **Skills**: [`frontend-ui-ux`, `git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 13, 14)
  - **Blocks**: Tasks 14 (party creation refactor depends on balance), 16 (ticket recommendation needs balance awareness)
  - **Blocked By**: Task 1 (auth changes should be stable)

  **References**:

  **Documentation References**:
  - `conductor/tracks/party_balance_system_20260117/spec.md` — Full specification
  - `conductor/tracks/party_balance_system_20260117/plan.md` — Implementation plan

  **Acceptance Criteria**:

  ```bash
  supabase test db
  # Assert: Balance-related pgTAP tests pass (add new tests for new migration)

  flutter analyze
  # Assert: No errors in both apps
  ```

  **Commit**: YES
  - Message: `feat(balance): implement party gender/group balance system`

---

- [ ] 13. Secure File Management System (M4-Track 2)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/secure_file_management_system_20260119/`
  - Build on migration `13_file_management.sql` (already exists)
  - Implement secure file access patterns with Supabase Storage
  - Add file management UI components

  **Must NOT do**:
  - Do NOT modify storage bucket migration (already deployed)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Migration already exists, primarily wiring up existing infrastructure
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 12, 14)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:

  **Documentation References**:
  - `conductor/tracks/secure_file_management_system_20260119/spec.md` — Full specification
  - `conductor/tracks/secure_file_management_system_20260119/plan.md` — Implementation plan
  - `backend/supabase/migrations/20260119200000_13_file_management.sql` — Existing migration

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors
  ```

  **Commit**: YES
  - Message: `feat(files): implement secure file management system`

---

- [ ] 14. Party Creation Logic Refactor — Max Capacity + Ticket Quantity Integration (M4-Track 9)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/party_creation_logic_refactor_20260118/`
  - Refactor max capacity logic to integrate with ticket quantities
  - Ensure balance system (Task 12) config is respected in capacity calculations

  **Must NOT do**:
  - Do NOT break existing party creation flow

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Complex business logic refactor touching backend + frontend
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (partially, shares Wave 4 resources)
  - **Parallel Group**: Wave 4 (with Tasks 12, 13)
  - **Blocks**: Task 15 (payment flow needs stable party/ticket structure)
  - **Blocked By**: Task 12 (balance system informs capacity logic)

  **References**:

  **Documentation References**:
  - `conductor/tracks/party_creation_logic_refactor_20260118/spec.md` — Full specification
  - `conductor/tracks/party_creation_logic_refactor_20260118/plan.md` — Implementation plan
  - `conductor/archive/party_creation_logic_refactor_20260118/spec.md` — Archived version (may have additional context)

  **Acceptance Criteria**:

  ```bash
  supabase test db
  # Assert: All tests pass including any new capacity-related tests

  flutter analyze
  # Assert: No errors in both apps
  ```

  **Commit**: YES
  - Message: `refactor(party): integrate max capacity with ticket quantity logic`

---

- [ ] 15. User Payment & Ticketing Flow — E2E Purchase Experience (M4-Track 3)

  **What to do**:
  - Implement per existing spec: `conductor/archive/user_payment_ticketing_flow_20260119/spec.md`
  - Build ticket selection → Iamport V1 payment → server verification → ticket issuance flow
  - Integrate with `verify-payment-v1` Edge Function (already exists)
  - Implement `TicketSelectionSheet` UI
  - Handle payment success/failure states
  - Post-payment ticket creation in DB

  **Must NOT do**:
  - Do NOT implement refund logic (that's Task 17)
  - Do NOT modify the `verify-payment-v1` Edge Function (already implemented)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Complex UI flow (multi-step wizard) + payment integration
  - **Skills**: [`frontend-ui-ux`, `git-master`]
    - `frontend-ui-ux`: Multi-step payment UX with error states

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 16)
  - **Blocks**: Task 17 (refund depends on payment existing)
  - **Blocked By**: Task 1 (auth gate on `/events/:eventId/apply`), Task 14 (party creation refactor for stable ticket structure)

  **References**:

  **Documentation References**:
  - `conductor/archive/user_payment_ticketing_flow_20260119/spec.md` — Full specification

  **Pattern References**:
  - `apps/app_user/lib/src/features/event/admission/event_application_wizard_screen.dart` — Existing wizard pattern
  - `apps/app_user/lib/src/features/event/admission/event_application_controller.dart` — Application controller
  - `apps/app_user/lib/src/features/ticket/ui/ticket_selection_sheet.dart` — Existing ticket selection UI

  **API References**:
  - `backend/supabase/functions/verify-payment-v1/index.ts` — Payment verification Edge Function

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors (working-directory: apps/app_user)
  ```

  **Commit**: YES
  - Message: `feat(payment): implement user payment and ticketing flow`

---

- [ ] 16. Ticket Recommendation — Optimal Ticket Auto-Suggestion (M4-Track 8)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/ticket_recommendation_20260118/`
  - Recommend best ticket based on entry conditions (entry group, balance status)
  - Integrate with balance system (Task 12) to show available vs locked tickets
  - Implement purchase restrictions based on entry conditions

  **Must NOT do**:
  - Do NOT implement AI-based recommendation (simple rule-based logic per spec)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Business logic for ticket eligibility and recommendation rules
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 15)
  - **Blocks**: None
  - **Blocked By**: Task 12 (needs balance system for availability awareness)

  **References**:

  **Documentation References**:
  - `conductor/tracks/ticket_recommendation_20260118/spec.md` — Full specification
  - `conductor/tracks/ticket_recommendation_20260118/plan.md` — Implementation plan

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors (working-directory: apps/app_user)
  ```

  **Commit**: YES
  - Message: `feat(tickets): implement ticket recommendation based on entry conditions`

---

- [ ] 17. User Refund & Cancellation System (M4-Track 4)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/user_refund_cancellation_system_20260119/`
  - Build `RefundCalculator` class (time-based refund percentage)
  - Add "예매 취소" button to ticket detail screen
  - Implement refund confirmation dialog with fee disclosure
  - Integrate with `cancel-payment` Edge Function (already exists)
  - Handle partial refund amounts

  **Must NOT do**:
  - Do NOT implement admin override for refund policies
  - Do NOT modify the existing refund trigger migration

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI for refund flow + business logic for calculator
  - **Skills**: [`frontend-ui-ux`, `git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 6 (sequential)
  - **Blocks**: Task 18 (settlement needs refund data)
  - **Blocked By**: Task 15 (payment must exist to refund)

  **References**:

  **Documentation References**:
  - `conductor/tracks/user_refund_cancellation_system_20260119/spec.md` — Full specification

  **Pattern References**:
  - `backend/supabase/functions/cancel-payment/index.ts` — Existing cancel payment Edge Function
  - `backend/supabase/migrations/20260118000002_09_refund_trigger.sql` — Refund trigger logic

  **Acceptance Criteria**:

  ```bash
  flutter analyze
  # Assert: No errors (working-directory: apps/app_user)

  deno test --allow-all backend/supabase/functions/cancel-payment/
  # Assert: Tests pass
  ```

  **Commit**: YES
  - Message: `feat(refund): implement user refund and cancellation system`

---

- [ ] 18. Partner Settlement & Revenue Dashboard (M4-Track 5)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/partner_settlement_dashboard_20260119/`
  - Create `settlements` table (new migration)
  - Build PostgreSQL views for revenue statistics
  - Set up `pg_cron` job for post-event settlement status transition
  - Build partner app dashboard UI with:
    - Revenue summary (total sales, refunds, net settlement)
    - Per-event settlement status list
    - Fee breakdown (PG fee, platform fee, VAT)
  - Add chart visualization for daily/monthly trends

  **Must NOT do**:
  - Do NOT implement actual bank transfer integration (out of scope)
  - Do NOT add settlement for cancelled/failed events

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Dashboard UI with charts + backend views + pg_cron scheduling
  - **Skills**: [`frontend-ui-ux`, `git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 6 (after Task 17)
  - **Blocks**: None
  - **Blocked By**: Task 17 (needs refund system for accurate settlement calculations)

  **References**:

  **Documentation References**:
  - `conductor/tracks/partner_settlement_dashboard_20260119/spec.md` — Full specification
  - `conductor/tracks/partner_settlement_dashboard_20260119/plan.md` — Implementation plan

  **Acceptance Criteria**:

  ```bash
  supabase test db
  # Assert: Settlement-related pgTAP tests pass

  flutter analyze
  # Assert: No errors (working-directory: apps/app_partner)
  ```

  **Commit**: YES
  - Message: `feat(settlement): implement partner settlement and revenue dashboard`

---

- [ ] 19. iOS Build CI/CD (M4-Track 6)

  **What to do**:
  - Implement per existing spec: `conductor/tracks/ios_build_cicd_20260119/`
  - Set up iOS build workflow in GitHub Actions
  - Configure code signing (certificates, provisioning profiles)
  - Add to CI pipeline with appropriate path filters
  - Configure TestFlight deployment

  **Must NOT do**:
  - Do NOT set up App Store production deployment
  - Do NOT modify existing Android CI/CD

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: iOS CI/CD is complex (code signing, provisioning, Xcode config)
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 7 (final)
  - **Blocks**: None
  - **Blocked By**: Tasks 8, 9 (CI pipeline should be stable before adding iOS builds)

  **References**:

  **Documentation References**:
  - `conductor/tracks/ios_build_cicd_20260119/spec.md` — Full specification
  - `conductor/tracks/ios_build_cicd_20260119/plan.md` — Implementation plan
  - `conductor/archive/android_build_cicd_20260118/spec.md` — Android CI/CD (reference pattern)

  **Acceptance Criteria**:

  ```bash
  # Verify workflow file exists:
  ls .github/workflows/ios*.yml
  # Assert: iOS workflow file exists

  # Verify it's syntactically valid:
  yamllint .github/workflows/ios*.yml
  # Assert: No errors
  ```

  **Commit**: YES
  - Message: `ci: add iOS build and TestFlight deployment pipeline`

---

## Commit Strategy

| After Task | Message | Verification |
|------------|---------|--------------|
| 1 | `feat(auth): allow unauthenticated access to party browsing routes` | flutter analyze + test |
| 2 | `feat(db): set up pgTAP infrastructure with test helpers` | supabase test db |
| 3 | `test(functions): add comprehensive Deno unit tests for all Edge Functions` | deno test --allow-all |
| 4 | `test(db): add pgTAP schema and constraint tests for all 13 migrations` | supabase test db |
| 5 | `test(db): add pgTAP RLS policy tests for all domains` | supabase test db |
| 6 | `test(db): add pgTAP trigger and function tests` | supabase test db |
| 7 | `feat(user): implement notification settings screen` | flutter analyze + test |
| 8 | `ci: add pgTAP database tests to CI pipeline` | YAML lint |
| 9 | `ci: add Edge Function Deno tests to CI pipeline` | YAML lint |
| 10 | `ci: add coverage reporting and format/lint enforcement` | YAML lint |
| 11 | `feat(user): implement sharing system with dynamic links` | flutter analyze |
| 12 | `feat(balance): implement party gender/group balance system` | supabase test db + flutter analyze |
| 13 | `feat(files): implement secure file management system` | flutter analyze |
| 14 | `refactor(party): integrate max capacity with ticket quantity logic` | flutter analyze |
| 15 | `feat(payment): implement user payment and ticketing flow` | flutter analyze |
| 16 | `feat(tickets): implement ticket recommendation based on entry conditions` | flutter analyze |
| 17 | `feat(refund): implement user refund and cancellation system` | flutter analyze + deno test |
| 18 | `feat(settlement): implement partner settlement and revenue dashboard` | supabase test db + flutter analyze |
| 19 | `ci: add iOS build and TestFlight deployment pipeline` | YAML lint |

---

## Success Criteria

### Verification Commands
```bash
# DB Tests (all pgTAP)
cd backend && supabase test db  # Expected: All tests pass

# Edge Function Tests
cd backend/supabase && deno test --allow-all functions/  # Expected: All tests pass

# Flutter Apps
cd apps/app_user && flutter analyze && flutter test  # Expected: No errors, tests pass
cd apps/app_partner && flutter analyze && flutter test  # Expected: No errors, tests pass

# CI Pipeline
gh workflow run ci.yml  # Expected: All jobs green

# Auth (manual)
# Browse /events/:id without login → renders event
# Try /my without login → redirected to /login?from=%2Fmy
```

### Final Checklist
- [ ] All 13 migrations covered by pgTAP tests
- [ ] All 8 Edge Functions have Deno unit tests
- [ ] CI runs DB + Edge Function + Flutter tests on PR
- [ ] Unauthenticated party browsing works
- [ ] All 11 pending tracks implemented per their specs
- [ ] Partner app remains fully auth-locked
- [ ] No regression in existing 22 completed tracks
