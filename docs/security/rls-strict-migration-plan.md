# RLS Strict Migration Plan

> **Issue**: #2393  
> **Date**: 2026-05-17  
> **Status**: Phase 2 완료 (#2990) — Phase 3~4 구현 완료 (#2991), Phase 5 rollout pending

## 목표

Flutter 앱(publishable key)의 Supabase 직접 write를 전면 차단하고, 모든 write를 Edge Function 경유로 전환.
현재는 RLS 정책이 유일한 방어선이지만, Postgres GRANT 레벨에서 일괄 차단하는 것이 목표.

---

## Phase 1: 직접 write 흐름 Inventory (완료)

> Audit date: 2026-05-17. `shared/packages/minglit_kit/lib/src/data/repositories/` 전수 조사.

### 직접 DB write 잔존 목록 (Phase 2 대상)

#### User-side

| 파일 | 메서드 | 테이블 | 작업 | EF 대안 |
|------|--------|--------|------|---------|
| `social_repository.dart:96` | `blockPartner()` | `social_interactions` | UPSERT | `user-manage-social` ← 이미 존재, 미사용 |
| `social_repository.dart:115` | `unblockPartner()` | `social_interactions` | DELETE | `user-manage-social` ← 이미 존재, 미사용 |
| `social_repository.dart:135` | `reportPartner()` | `social_interactions` | UPSERT | `user-manage-social` ← 이미 존재, 미사용 |
| `social_repository.dart:141` | `reportPartner()` | `report_details` | INSERT | `user-manage-social` ← 이미 존재, 미사용 |
| `notification_repository.dart:79` | `markAsRead()` | `user_notifications` | UPDATE | `user-manage-notification` ← 이미 존재, 미사용 |
| `notification_repository.dart:94` | `markAllAsRead()` | `user_notifications` | UPDATE | `user-manage-notification` ← 이미 존재, 미사용 |
| `notification_repository.dart:109` | `deleteNotification()` | `user_notifications` | DELETE | `user-manage-notification` ← 이미 존재, 미사용 |
| `event_repository_commands.dart:42` | `deleteApplication()` | `event_applications` | DELETE | 신규 EF 필요 (`user-cancel-order` 확장 or 별도) |

#### Partner-side

| 파일 | 메서드 | 테이블 | 작업 | EF 대안 |
|------|--------|--------|------|---------|
| `party_event_repository.dart:31` | `createEvent()` | `events` | INSERT | `partner-manage-party` / `partner-manage-event` ← 이미 존재 |
| `party_event_repository.dart:43` | `createEvent()` | `entry_groups` | INSERT | `partner-manage-party` ← 이미 존재 |
| `party_event_repository.dart:53` | `createEvent()` | `tickets` | INSERT | `partner-manage-event` ← 이미 존재 |
| `party_event_repository.dart:72` | `updateEvent()` | `events` | UPDATE | `partner-manage-event` ← 이미 존재 |
| `party_event_repository.dart:92` | `updateEventStatus()` | `events` | UPDATE | `partner-manage-event` ← 이미 존재 |
| `party_event_repository.dart:109` | `updateEventMetadata()` | `events` | UPDATE | `partner-manage-event` ← 이미 존재 |
| `location_repository.dart:82` | `createLocation()` | `locations` | INSERT | `partner-manage-party` ← 이미 존재 |
| `location_repository.dart:126` | `updateLocationDetails()` | `locations` | UPDATE | `partner-manage-party` ← 이미 존재 |
| `ticket_repository.dart:146` | `updateTicketTemplate()` | `ticket_templates` | UPDATE | `partner-manage-event` ← 확인 필요 |
| `ticket_repository.dart:168` | `createTicketTemplate()` | `ticket_templates` | INSERT | `partner-manage-event` ← 확인 필요 |
| `ticket_repository.dart:185` | `deleteTicketTemplate()` | `ticket_templates` | DELETE | 신규 EF 필요 |
| `ticket_repository.dart:205` | `createTicket()` | `tickets` | INSERT | `partner-manage-event` ← 이미 존재 |
| `ticket_repository.dart:240` | `updateTicket()` | `tickets` | UPDATE | `partner-manage-event` ← 이미 존재 |
| `party_matching_repository.dart:17` | `replaceEntryGroupTemplates()` | `entry_group_templates` | DELETE | 신규 EF 필요 |
| `party_matching_repository.dart:30` | `replaceEntryGroupTemplates()` | `entry_group_templates` | INSERT | 신규 EF 필요 |
| `settlement_repository.dart:276` | `upsertBankAccount()` | `partner_settlements` | UPSERT | `partner-manage-settlement` 확인 필요 |
| `partner_application_repository.dart:164` | `reviewApplication()` | `partner_applications` | UPDATE | 신규 EF 필요 (`partner-review-application` 등) |
| `verification_command_repository.dart:301` | `updateApplicationStatus()` | `event_applications` | UPDATE | `partner-approve-application` / `partner-reject-application` 확인 필요 |

### 이미 EF 경유 완료 (Phase 2 대상 아님)

| 메서드 | EF |
|--------|----|
| `applyEvent()` | `apply-event` |
| `cancelOrder()` | `user-cancel-order` |
| `confirmPayment()` | `payment-verify` |
| `cancelPayment()` | `payment-cancel` |
| `approveApplication()` | `partner-approve-application` |
| `rejectApplication()` | `partner-reject-application` |
| `bulkApproveApplications()` | `partner-approve-application` |
| `markMatchResultsViewed()` | `user-mark-match-results-viewed` |
| `saveUserVerificationData()` | `user-update-verification` |
| `submitVerificationToPartner()` | `user-submit-verification` |
| `createVerification()` | `partner-manage-verification` |
| `reviewRequest()` | `partner-review-submission` |
| `upsertToken()` (FCM) | `user-manage-settings` |
| `deleteToken()` (FCM) | `user-manage-settings` |
| `updateSettings()` | `user-manage-settings` |
| `submitApplication()` | `partner-register` |
| `saveDraft()` | `partner-register` |

### Phase 1 당시 EF 보강 필요 항목

아래 항목은 Phase 2 (#2990)에서 처리 완료.

| 항목 | 근거 |
|------|------|
| `event_applications.DELETE` (deleteApplication) | user-cancel-order가 status 변경만 처리, hard delete 미지원 |
| `ticket_templates.DELETE` | 기존 EF에 delete 액션 없음 (확인 후 기존 EF에 추가 or 별도) |
| `entry_group_templates` CRUD | 기존 EF 미지원 |
| `partner_applications.UPDATE` (reviewApplication) | 기존 approve/reject EF는 event_applications 대상 |

---

## Phase 2: 직접 write → EF 마이그레이션 (완료)

> Tracking issue: #2990
> Verification date: 2026-06-03

### 완료 범위

| 영역 | 처리 |
|------|------|
| Social / Notification write | `user-manage-social`, `user-manage-notification` 경유 |
| Event create/update, entry groups, tickets | `partner-manage-event` 경유 |
| Location, ticket template, entry group template | `partner-manage-party` 경유 |
| Partner settlement bank account | `partner-manage-settlement` 경유 |
| Partner application review | `partner-register` `review` action 경유 |
| Event application approve/reject | `partner-approve-application`, `partner-reject-application` 경유 |
| User application delete/cancel | `user-cancel-order` 경유 |

### 완료 검증

```bash
rg -n "\.(insert|update|upsert|delete)\s*\(" \
  shared/packages/minglit_kit/lib/src/data/repositories --glob '*.dart'
```

2026-06-03 기준 결과 0건. Repository layer의 Supabase DB 직접 write는 제거되어 Phase 3 GRANT 회수 진행 가능.

---

## Phase 3: GRANT 회수 Migration (구현 완료, #2991)

> **전제조건**: Phase 2 완료. 2026-06-03 기준 repository layer 직접 DB write 0건 확인.

```sql
-- Migration:
-- supabase/migrations/20260603215321_rls_strict_revoke_publishable_writes.sql

-- service_role 전용 write policy는 TO service_role로 한정.
-- 남는 public/anon/authenticated write policy는 catalog loop로 제거.
-- write-capable SECURITY DEFINER RPC는 service_role 전용 EXECUTE로 한정.

-- 기존 앱 테이블 GRANT 회수
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA public
  FROM anon, authenticated;

-- 신규 테이블 자동 적용
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON TABLES
  FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE EXECUTE
  ON FUNCTIONS
  FROM PUBLIC, anon, authenticated;
```

PostGIS extension 객체(`spatial_ref_sys`, `geometry_columns`, `geography_columns`)는 `supabase_admin` 소유라 앱 write surface gate에서 제외한다.

**롤백 원칙**: 이 migration은 GRANT만이 아니라 클라이언트 write policy도 제거한다. 긴급하게 publishable DB write를 다시 열어야 하면 새 forward migration에서 아래 GRANT와 함께 제거된 policy 정의를 `20260525000001_rls_auth_initplan.sql`, `20260525000002_consolidate_select_rls_policies.sql` 기준으로 복원한다.
```sql
GRANT INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA public
  TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT INSERT, UPDATE, DELETE, TRUNCATE
  ON TABLES
  TO anon, authenticated;

-- 필요한 write RPC 예외가 있다면 함수별로만 복원한다.
GRANT EXECUTE ON FUNCTION public.<function_signature>
  TO authenticated;
```

---

## Phase 4: 회귀 테스트 (구현 완료, #2991)

- pgTAP: `107_rls_strict_publishable_write_lockdown_test.sql`
  - 앱 public relation에서 `anon/authenticated` write GRANT 0건
  - `pg_policies`에서 public/anon/authenticated write policy 0건
  - write-capable SECURITY DEFINER RPC에서 `anon/authenticated` EXECUTE 0건
  - `SET ROLE authenticated/anon; INSERT INTO public.tags ...` → `42501`
  - `SET ROLE service_role; INSERT INTO public.tags ...` → success
- 기존 RLS pgTAP: self/partner direct write 성공 기대값을 permission denied 기대값으로 전환.
- Flutter integration: publishable key HTTP write smoke는 dev rollout 후 운영 모니터링에서 확인.

---

## Phase 5: Rollout (pending)

1. dev 적용 → 1주일 모니터링
2. 에러 발생 시 롤백 SQL 즉시 실행
3. 이상 없으면 main 적용

---

## 참고

- EF auth-manifest: `supabase/functions/_shared/auth-manifest.ts` (or `.json`)
- 아키텍처: `docs/architecture/backend.md`, `docs/architecture/edge-function-auth.md`
- minglitEdgeFunction wrapper: `supabase/functions/_shared/`
