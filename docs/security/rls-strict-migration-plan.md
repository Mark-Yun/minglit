# RLS Strict Migration Plan

> **Issue**: #2393  
> **Date**: 2026-05-17  
> **Status**: Phase 1 완료 — Phase 2~5 pending

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

### 신규 EF가 필요한 항목

| 항목 | 근거 |
|------|------|
| `event_applications.DELETE` (deleteApplication) | user-cancel-order가 status 변경만 처리, hard delete 미지원 |
| `ticket_templates.DELETE` | 기존 EF에 delete 액션 없음 (확인 후 기존 EF에 추가 or 별도) |
| `entry_group_templates` CRUD | 기존 EF 미지원 |
| `partner_applications.UPDATE` (reviewApplication) | 기존 approve/reject EF는 event_applications 대상 |

---

## Phase 2: 직접 write → EF 마이그레이션 (미착수)

### 우선순위

**Group A — EF 이미 존재, Flutter만 수정**
- `social_repository.dart` 3개 write → `user-manage-social` 사용
- `notification_repository.dart` 3개 write → `user-manage-notification` 사용
- `party_event_repository.dart` + `location_repository.dart` + `ticket_repository.dart` → `partner-manage-party` / `partner-manage-event` 사용

**Group B — EF 기능 확장 후 Flutter 수정**
- `settlement_repository.dart` → `partner-manage-settlement` 확인 후 upsert 액션 추가
- `verification_command_repository.dart:301` → `partner-approve-application` / `partner-reject-application` 확인
- `ticket_repository.dart:185` (DELETE) → `partner-manage-event`에 delete_ticket_template 액션 추가

**Group C — 신규 EF 필요**
- `event_applications.DELETE` → `user-cancel-order` 확장 or 별도 EF
- `partner_applications.UPDATE` → `partner-review-application` EF 신규 생성
- `entry_group_templates` CRUD → 기존 EF에 통합 or 별도

---

## Phase 3: GRANT 회수 Migration (미착수)

> **전제조건**: Phase 2 완료 후 진행. Phase 2 미완료 시 진행 금지.

```sql
-- Migration: supabase/migrations/YYYYMMDD000001_revoke_write_grants_from_publishable_key.sql

-- 기존 테이블 GRANT 회수
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA public
  FROM anon, authenticated;

-- 신규 테이블 자동 적용
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  FROM anon, authenticated;
```

**롤백 SQL** (긴급 시 즉시 실행):
```sql
GRANT INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA public
  TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT INSERT, UPDATE, DELETE, TRUNCATE
  TO anon, authenticated;
```

---

## Phase 4: 회귀 테스트 (미착수)

- pgTAP: `SET ROLE authenticated; INSERT INTO public.<table> ...` → 모든 public 테이블 fail 검증
- Flutter integration: publishable key write → 403 확인

---

## Phase 5: Rollout (미착수)

1. dev 적용 → 1주일 모니터링
2. 에러 발생 시 롤백 SQL 즉시 실행
3. 이상 없으면 main 적용

---

## 참고

- EF auth-manifest: `supabase/functions/_shared/auth-manifest.ts` (or `.json`)
- 아키텍처: `docs/architecture/backend.md`, `docs/architecture/edge-function-auth.md`
- minglitEdgeFunction wrapper: `supabase/functions/_shared/`
