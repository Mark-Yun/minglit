# RLS Write Strategy Migration Plan

## 원칙

클라이언트(user/partner)는 **READ-only RLS**만 갖고, **쓰기/삭제는 Edge Function**을 통해 수행한다.

- SELECT: RLS 정책으로 클라이언트 직접 조회
- INSERT / UPDATE / DELETE: Edge Function → `service_role`로 수행

## 현재 상태 (2026-03-22 기준)

### 클라이언트 직접 write 테이블: 21개

| # | 테이블 | Repository | 직접 write ops | 기존 EF |
|---|--------|-----------|---------------|---------|
| 1 | `parties` | party_repository | insert, update (4곳) | 없음 |
| 2 | `events` | party_event_repository | insert, update (4곳) | 없음 |
| 3 | `tickets` | ticket_repository | insert, update | 없음 |
| 4 | `ticket_templates` | ticket_repository | insert, update, delete | 없음 |
| 5 | `entry_groups` | party_repository, party_matching_repository | insert, delete | 없음 |
| 6 | `event_applications` | event_repository_commands | delete, update (2곳) | payment-verify, payment-cancel, payment-webhook |
| 7 | `verification_submissions` | verification_command_repository, event_repository_commands | insert, update, delete | 없음 |
| 8 | `verifications` | verification_command_repository | insert, update (3곳) | 없음 |
| 9 | `verification_comments` | verification_command_repository | insert | 없음 |
| 10 | `user_verifications` | verification_command_repository | upsert | 없음 |
| 11 | `social_interactions` | social_repository | insert, delete, upsert | 없음 |
| 12 | `report_details` | social_repository | insert | 없음 |
| 13 | `fcm_tokens` | notification_repository | upsert, delete | notification-worker |
| 14 | `user_notifications` | notification_repository | update, delete | notification-worker |
| 15 | `user_settings` | notification_repository | upsert | 없음 |
| 16 | `match_rules` | matching_repository | insert, delete | 없음 |
| 17 | `match_votes` | matching_repository | insert | 없음 |
| 18 | `partner_applications` | partner_application_repository | insert, update (4곳) | 없음 |
| 19 | `partner_member_permissions` | partner_member_repository | update (2곳) | 없음 |
| 20 | `partner_settlements` | settlement_repository | upsert | 없음 |
| 21 | `locations` | location_repository | insert, update | 없음 |

### RLS 위반 정책 (user/partner의 INSERT/UPDATE/DELETE)

**User 직접 write:**

| 테이블 | 정책 | cmd |
|--------|------|-----|
| `event_applications` | Users can create/update own applications | INSERT, UPDATE |
| `fcm_tokens` | Users can insert/delete their own | INSERT, DELETE |
| `match_votes` | Users can cast votes | INSERT |
| `social_interactions` | Users can manage own interactions | ALL |
| `user_notifications` | Users can update own notifications | UPDATE |
| `user_profiles` | Users can update own profile | UPDATE |
| `user_settings` | Users can insert/update own settings | INSERT, UPDATE |
| `user_verifications` | Users can read/write own | ALL |
| `verification_submissions` | Users can create own submissions | INSERT |
| `verification_comments` | comments CRUD | INSERT, UPDATE, DELETE |
| `report_details` | Users can insert own reports | INSERT |
| `partner_applications` | authenticated can apply | INSERT |

**Partner Admin/Owner ALL 정책:**

| 테이블 | 정책 |
|--------|------|
| `entry_group_templates` | Admin/Owner all access |
| `entry_groups` | Admin/Owner all access |
| `events` | Admin/Owner all access |
| `locations` | Admin/Owner all access |
| `parties` | Admin/Owner all access |
| `partners` | Admin/Owner all access |
| `ticket_templates` | Admin/Owner all access |
| `tickets` | Admin/Owner all access |
| `verifications` | Admin/Owner all access |
| `partner_member_permissions` | member manage INSERT/UPDATE/DELETE |
| `partner_settlements` | settlement UPDATE/DELETE |
| `verification_submissions` | Partner staff UPDATE |

### 기존 Edge Function write 매핑

| Edge Function | 테이블 | 동작 |
|---------------|--------|------|
| `payment-verify` | `event_applications` | UPDATE (status, payment_id, paid_at) |
| `payment-cancel` | `event_applications` | UPDATE (refund_status, refund_amount) |
| `payment-webhook` | `event_applications` | UPDATE (status, payment_id) |
| `profile-update` | `user_embeddings` | UPSERT |
| `identity-verify` | `user_profiles` | UPDATE (name, birth_date, gender 등) |
| `notification-worker` | `fcm_tokens`, `user_notifications` | DELETE, INSERT |
| `partner-sync` | `partners` | UPDATE (portone_partner_id) |
| `reconciliation-daily` | `reconciliation_runs`, `reconciliation_results` | INSERT, UPDATE |
| `payout-sync` | `payout_transfers`, `settlement_items` | INSERT, UPDATE |
| `settlement-register-transfers` | `settlement_items` | UPDATE |
| `vector-worker` | `debug_logs`, `party_embeddings`, `user_embeddings` | INSERT, DELETE, UPSERT |

## Migration Plan

### Phase 1: 신규 Edge Function 생성

기존 EF가 없어서 새로 만들어야 하는 것들. 도메인별로 묶어서 EF 생성.

#### EF 네이밍 규칙

`{호출자}-{동작}` 형식. 호출자(user/partner)를 앞에 붙여 누가 호출하는 EF인지 명확히 한다.

예: `user-create-order`, `partner-update-party`, `user-cast-vote`

#### 1-1. User 도메인
| EF 이름 | 담당 테이블 | 대응 Repository |
|---------|------------|----------------|
| `user-manage-social` | social_interactions, report_details | social_repository |
| `user-cast-vote` | match_votes | matching_repository |
| `user-manage-settings` | user_settings, fcm_tokens | notification_repository |
| `user-manage-notification` | user_notifications (update/delete) | notification_repository |
| `user-apply-event` | event_applications, verification_submissions | event_repository_commands |
| `user-apply-partner` | partner_applications | partner_application_repository |

#### 1-2. Partner 도메인
| EF 이름 | 담당 테이블 | 대응 Repository |
|---------|------------|----------------|
| `partner-manage-party` | parties, entry_groups, ticket_templates, locations | party_repository, location_repository |
| `partner-manage-event` | events, tickets, entry_groups | party_event_repository, ticket_repository |
| `partner-manage-verification` | verifications, verification_submissions, verification_comments, user_verifications | verification_command_repository |
| `partner-manage-match` | match_rules | matching_repository |
| `partner-manage-member` | partner_member_permissions | partner_member_repository |
| `partner-manage-settlement` | partner_settlements | settlement_repository |

### Phase 2: Flutter 클라이언트 전환

각 Repository에서 직접 Supabase `.insert()/.update()/.delete()` → EF 호출로 전환.

| 순서 | Repository | 변경 규모 | 우선순위 |
|------|-----------|----------|---------|
| 1 | social_repository | 6곳 | 높음 (ALL 정책 위험) |
| 2 | notification_repository | 6곳 | 높음 |
| 3 | event_repository_commands | 5곳 | 높음 (결제 관련) |
| 4 | matching_repository | 3곳 | 중간 |
| 5 | party_repository | 8곳 | 중간 (파트너 전용) |
| 6 | party_event_repository | 5곳 | 중간 (파트너 전용) |
| 7 | ticket_repository | 5곳 | 중간 (파트너 전용) |
| 8 | verification_command_repository | 8곳 | 중간 |
| 9 | partner_application_repository | 6곳 | 낮음 |
| 10 | location_repository | 2곳 | 낮음 |
| 11 | partner_member_repository | 2곳 | 낮음 |
| 12 | settlement_repository | 1곳 | 낮음 |

### Phase 3: RLS 정책 전환

EF 전환 완료된 테이블부터 순차적으로:
1. write RLS 정책 제거 (INSERT/UPDATE/DELETE)
2. READ-only 정책만 남김
3. service_role 전용 ALL 정책 유지 (EF 내부용)

```sql
-- 예시: social_interactions 전환 후
DROP POLICY "Users can manage own interactions" ON public.social_interactions;
-- "Users can view own interactions" SELECT 정책만 유지
```

## 비고

- Phase 1~3은 테이블 단위로 병렬 진행 가능
- 각 Phase 완료 시 해당 테이블의 integration test 필수
- 기존 client CUJ 테스트가 깨지지 않도록 EF + Flutter 전환을 동시에 진행
