# Backend Architecture

Minglit의 Supabase 기반 백엔드 인프라를 기술한다.  
결제, 검색/추천, 인증/신뢰, 이벤트 파이프라인은 각각 별도 문서에서 다룬다.

---

## 1. Infrastructure Overview

### Postgres Extensions

| Extension | Schema | Purpose |
|-----------|--------|---------|
| **PostGIS** | public | 위치 기반 검색 (`geography(Point, 4326)`, `ST_DWithin`) |
| **pgvector** | extensions | 1536차원 임베딩, HNSW 코사인 유사도 — [상세](./search-and-recommendation.md) |
| **PGroonga** | public | 한글 전문 검색 (`&@~`, `&@`) — [상세](./search-and-recommendation.md) |
| **PGMQ** | pgmq | 메시지 큐 (3개 큐) — [상세](./global-event-pipeline.md) |
| **pg_cron** | cron | 스케줄링 (알림, 리마인더, 정산 상태 전환) |
| **pg_net** | net | HTTP 요청 (Edge Function 호출, 환불 트리거) |
| **moddatetime** | extensions | `updated_at` 자동 갱신 트리거 |
| **supabase_vault** | vault | 시크릿 관리 (`service_role_key` 등) |

### Schema Strategy

단일 `public` 스키마에 모든 테이블을 배치한다. 도메인 분리는 migration 파일 단위로 관리:

| Migration | Domain | 주요 테이블 |
|-----------|--------|------------|
| `01_extensions_enums` | 인프라 | Enums, PGMQ 큐 생성 |
| `02_schema_core` | 사용자/파트너 | user_profiles, partners, verifications, locations |
| `03_schema_events` | 이벤트 | parties, events, entry_groups, tickets |
| `04_schema_commerce` | 커머스 | event_applications, verification_submissions |
| `05_schema_system` | 시스템 | notifications, social, matching, files, settlements |
| `06_functions_triggers` | 로직 | PGMQ 래퍼, 파이프라인, RPC 함수 |
| `07_rls_grants` | 보안 | RLS 정책 40+개, GRANT 문 |
| `08_cron_routes` | 운영 | 크론 잡 3개, 이벤트 라우트 설정 |

---

## 2. Database Schema

### 2.1 Table Inventory

총 **29개 테이블** + **4개 뷰** + **3개 PGMQ 큐 테이블**.

#### Core (사용자/파트너)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `user_profiles` | 유저 프로필 | id (FK auth.users), username, birth_date, gender, is_verified, ci, di |
| `user_embeddings` | 유저 임베딩 | user_id (PK), embedding vector(1536) |
| `app_roles` | 앱 역할 | user_id (PK), role ('super_admin' \| 'moderator') |
| `user_actions` | 유저 행동 로그 | user_id, party_id, action_type (view/like/dislike/purchase) |
| `partners` | 파트너 조직 | name, biz_number, portone_partner_id, is_active |
| `partner_settlements` | 파트너 정산 정보 | partner_id (PK), biz_type, bank_name, account_number |
| `partner_member_permissions` | 파트너 멤버 권한 | partner_id, user_id, role (owner/manager/staff), permissions[] |
| `partner_applications` | 파트너 입점 신청 | user_id, status, brand_name, biz_type, biz_number |
| `locations` | 장소 | partner_id, address, geo_point geography(Point, 4326) |
| `verifications` | 인증 양식 정의 | partner_id, category, form_schema jsonb — [상세](./trust-and-verification.md) |

#### Events (이벤트/티켓)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `parties` | 파티 (이벤트 템플릿) | partner_id, title, image_urls[], balance_config, status (draft/active/closed), visibility (public/private) |
| `party_embeddings` | 파티 임베딩 | party_id (PK), embedding vector(1536) |
| `events` | 실제 이벤트 회차 | party_id, start_time, end_time, status (scheduled/cancelled/completed), visibility (public/private) |
| `entry_group_templates` | 입장 그룹 템플릿 (파티) | party_id, gender, birth_year_min/max |
| `entry_groups` | 입장 그룹 (이벤트) | event_id, gender, birth_year_min/max |
| `ticket_templates` | 티켓 템플릿 (파티) | party_id, name, price, quantity |
| `tickets` | 티켓 (이벤트) | event_id, name, price, quantity, sold_count, status |

#### Commerce (신청/인증/참가)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `event_applications` | 이벤트 신청 | event_id, ticket_id, user_id, status, payment_id, refund_status |
| `verification_submissions` | 인증 제출 | partner_id, user_id, verification_id, application_id, status, snapshot_data |
| `user_verifications` | 유저 인증 데이터 | user_id, verification_id, data jsonb |
| `partner_verified_users` | 인증 완료 유저 | partner_id, user_id, verification_id, verified_at, valid_until |
| `event_participants` | 참가 확정 | event_id, ticket_id, user_id, ticket_code, status |
| `verification_comments` | 인증 심사 코멘트 | submission_id, author_id, content jsonb |

#### System (알림/소셜/매칭/파일/정산)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `user_notifications` | 인앱 알림 | user_id, title, body, category, deep_link, is_read |
| `fcm_tokens` | FCM 푸시 토큰 | user_id, token, device_type (android/ios/web) |
| `user_settings` | 알림 설정 | user_id, marketing_consent, service_notification |
| `social_interactions` | 소셜 상호작용 | user_id, target_id, target_type, interaction_type (like/subscribe/bookmark/block) |
| `match_rules` | 매칭 규칙 | event_id, source_group_id, target_group_id |
| `match_votes` | 매칭 투표 | event_id, voter_id, candidate_id |
| `match_pairs` | 매칭 결과 | event_id, user_lower_id, user_higher_id, matched_at |
| `minglit_files` | 파일 메타데이터 | storage_object_id, bucket_id, file_path, owner_id |
| `file_access_grants` | 파일 접근 권한 | file_id, viewer_id, expires_at |
| `settlements` | 정산 | partner_id, event_id, total_sales, net_amount, status — [상세](./payment-pipeline.md) |
| `report_details` | 신고 상세 정보 | social_interaction_id, target_type, reason, description |

#### PGMQ Infrastructure

| Table | Purpose |
|-------|---------|
| `processed_events` | 중복 처리 방지 (idempotency) |
| `dead_letter_queue` | 실패 메시지 보관 (msg_id, queue_name, error_reason) |
| `event_routes` | 이벤트 → 큐 라우팅 설정 |
| `debug_logs` | 디버그 로그 (service_role 전용) |

#### Views

| View | Purpose |
|------|---------|
| `locations_view` | 위치 + lat/lng 변환 |
| `partner_revenue_stats` | 파트너별 총 매출/환불/순수익 |
| `partner_monthly_revenue` | 파트너별 월간 매출 |
| `my_matches_view` | 내 매칭 결과 (상대방 ID) |

### 2.2 Entity Relationships

```text
auth.users
  └── user_profiles (1:1)
        ├── user_embeddings (1:1)
        ├── user_actions (1:N)
        └── user_settings (1:1)

partners
  ├── partner_member_permissions (1:N) ← auth.users
  ├── partner_settlements (1:1)
  ├── partner_applications (via user_id)
  ├── locations (1:N)
  ├── verifications (1:N)
  ├── parties (1:N)
  │     ├── party_embeddings (1:1)
  │     ├── entry_group_templates (1:N)
  │     ├── ticket_templates (1:N)
  │     └── events (1:N)
  │           ├── entry_groups (1:N)
  │           ├── tickets (1:N)
  │           ├── event_applications (1:N) ← user_profiles
  │           │     └── verification_submissions (1:N)
  │           │           └── partner_verified_users (result)
  │           ├── event_participants (1:N) ← user_profiles
  │           ├── match_rules (1:N)
  │           ├── match_votes (N:N)
  │           ├── match_pairs (N:N)
  │           └── settlements (1:1)
  └── settlements (1:N)
```

### 2.3 Enum Types

| Enum | Values |
|------|--------|
| `gender` | male, female |
| `partner_role` | owner, manager, staff |
| `verification_status` | pending, approved, rejected, needs_correction, cancelled |
| `verification_category` | career, asset, marriage, academic, vehicle, etc |
| `partner_application_status` | pending, approved, rejected, needs_correction |
| `user_action_type` | view, like, dislike, purchase |
| `event_queue_name` | q_global_events, q_notifications, q_vectors |
| `event_type_name` | party_created, user_interaction, application_approved, application_rejected, event_updated, event_cancelled, new_application, verification_result, event_reminder |
| `social_target_type` | party, partner, review, comment |
| `social_interaction_type` | like, subscribe, bookmark, block, report |
| `notification_category` | marketing, service, social |

---

## 3. Edge Functions

Supabase Edge Functions는 Deno 런타임 기반이며, `supabase/functions/` 디렉토리에 위치한다.

### 3.1 Function Inventory

| Function | Domain | Purpose |
|----------|--------|---------|
| `payment-verify` | Payment | 결제 검증 (Portone/Iamport) |
| `payment-webhook` | Payment | PG 웹훅 핸들러 |
| `payment-cancel` | Payment | 결제 취소/환불 |
| `settlement-query` | Payment | 정산 조회 |
| `settlement-transfer` | Payment | 정산 주문 이체 |
| `notification-worker` | Notification | FCM 푸시 알림 발송 (PGMQ consumer) |
| `vector-worker` | Recommendation | 파티/유저 임베딩 생성 (PGMQ consumer) |
| `vectorize-party` | Recommendation | 온디맨드 파티 벡터화 |
| `profile-update` | User | 프로필 업데이트 + 임베딩 생성 |
| `identity-verify` | Identity | 본인인증 (Portone V2/PASS) |
| `partner-sync` | Partner | 플랫폼 파트너 동기화 |
| `bug-report` | System | 버그 리포트 (파일 업로드 포함) |
| `health` | System | 시스템 헬스 체크 |
| `dev-seed` | Dev | 테스트 데이터 시딩 (dev only) |
| `dev-session-switch` | Dev | 테스트 유저 전환 (dev only) |

### 3.2 Shared Modules (`_shared/`)

| Module | LOC | Purpose |
|--------|-----|---------|
| `portone_client.ts` | 209 | Portone V2 API 클라이언트 (결제 검증, 취소) |
| `iamport_client.ts` | 63 | Iamport V1 레거시 API 래퍼 |
| `sentry_utils.ts` | 105 | Sentry 에러 트래킹 (`withSentry`, `withSentryHandler`) |
| `worker_utils.ts` | 58 | PGMQ 워커 유틸 (중복 체크, DLQ, 지연 로깅) |
| `auth_utils.ts` | 38 | 인증 유틸 (`requireAuth` — Bearer 토큰 → `auth.getUser()`) |
| `response_utils.ts` | 33 | HTTP 응답 헬퍼 (CORS, JSON/에러 응답) |

### 3.3 Dev Guard

`dev-seed`, `dev-session-switch`은 프로덕션 배포 시 `DENO_DEPLOYMENT_ID` 환경변수를 체크하여 403을 반환한다.

---

## 4. Authentication & Authorization

### 4.1 Supabase Auth

- OAuth 로그인 (Apple, Kakao 등)
- 회원 가입 시 `on_auth_user_created` 트리거 → `user_profiles` 자동 생성
- 동시에 `on_auth_user_created_settings` 트리거 → `user_settings` 기본값 생성
- Edge Function 인증: `auth_utils.ts`의 `requireAuth()` — Bearer 토큰을 `supabase.auth.getUser()`로 검증

### 4.2 Role System

**앱 역할** (`app_roles` 테이블):

| Role | 설명 |
|------|------|
| `super_admin` | 전체 시스템 관리자 |
| `moderator` | 중재자 (파트너 입점 심사 등) |

**파트너 역할** (`partner_role` enum):

| Role | Permissions |
|------|------------|
| `owner` | PARTNER_EDIT, SETTLEMENT_VIEW, SETTLEMENT_EDIT, MEMBER_MANAGE, PARTY_MANAGE, VERIFY_LIST_VIEW, USER_DATA_VIEW, VERIFY_REVIEW, COMMENT_MANAGE |
| `manager` | PARTNER_EDIT, PARTY_MANAGE, VERIFY_LIST_VIEW, USER_DATA_VIEW, VERIFY_REVIEW, COMMENT_MANAGE |
| `staff` | VERIFY_LIST_VIEW, COMMENT_MANAGE, PARTY_MANAGE |

Permission은 `partner_member_permissions.permissions` 배열에 저장되며, role 변경 시 `trigger_sync_permissions` 트리거가 자동으로 동기화한다.

### 4.3 Security Functions

```sql
-- super_admin 여부 (app_roles 테이블 조회)
is_super_admin() → boolean

-- 파트너 특정 권한 보유 여부 (super_admin이면 항상 true)
has_partner_permission(partner_id, permission_key) → boolean

-- 유저 프로필 보호 (is_verified 필드는 super_admin만 변경 가능)
protect_user_profile_fields() → trigger
```

---

## 5. RLS (Row Level Security)

모든 테이블에 RLS가 활성화되어 있다. 정책 패턴:

### 5.1 Policy Patterns

| Pattern | 적용 대상 | 설명 |
|---------|----------|------|
| **Self-only** | user_profiles, user_settings, social_interactions | `auth.uid() = user_id` |
| **Public read** | partners, parties, events, tickets, locations, verifications | `for select using (true)` |
| **Partner-scoped** | partner_member_permissions, verification_submissions | `has_partner_permission(partner_id, 'KEY')` |
| **Admin-only** | app_roles, debug_logs, partner_applications (update/delete) | `is_super_admin()` |
| **Mixed** | event_applications, settlements | 본인 OR 파트너 권한 OR admin |

### 5.2 Policy Count by Table

| Table | Policies | Pattern |
|-------|----------|---------|
| user_profiles | 2 | Self-only (read, update) |
| app_roles | 1 | Admin-only |
| partners | 2 | Public read + Admin/Owner write |
| partner_settlements | 3 | Permission-based (read, update, admin delete) |
| partner_member_permissions | 4 | Self read + MEMBER_MANAGE (insert, update, delete) |
| partner_applications | 4 | Self read + Admin write |
| events | 2 | Public read + Partner/Admin write |
| event_applications | 4 | Self (read, create, update) + Partner staff read |
| verification_submissions | 4 | Self + Partner staff (read, update) |
| verification_comments | 4 | Multi-role (read, insert, update, delete) |
| settlements | 1 | Admin + SETTLEMENT_VIEW |
| storage.objects | 9 | Bucket-specific (verification-proofs, party-assets, partner-proofs) |

### 5.3 Storage Buckets

| Bucket | Public | Upload Policy | View Policy |
|--------|--------|---------------|-------------|
| `verification-proofs` | No | 본인 폴더만 | 본인 + 파일 접근 권한 + 파트너/관리자 |
| `party-assets` | Yes | Authenticated | 전체 공개 |
| `partner-proofs` | No | 본인 폴더만 | 본인 + 관리자 |

---

## 6. Key Triggers & Functions

### 6.1 Business Logic Triggers

| Trigger | Table | Event | Action |
|---------|-------|-------|--------|
| `on_auth_user_created` | auth.users | INSERT | user_profiles 생성 |
| `on_auth_user_created_settings` | auth.users | INSERT | user_settings 기본값 생성 |
| `protect_user_profile_fields` | user_profiles | UPDATE | is_verified 필드 보호 |
| `trigger_sync_permissions` | partner_member_permissions | INSERT/UPDATE | role → permissions 자동 동기화 |
| `on_ticket_change` | tickets | INSERT/UPDATE/DELETE | events.max_participants 동기화 |
| `on_ticket_template_change` | ticket_templates | INSERT/UPDATE/DELETE | parties.max_participants 동기화 |
| `on_participant_change` | event_participants | INSERT/DELETE | events.current_participants ± 1, tickets.sold_count ± 1 |
| `on_submission_status_change` | verification_submissions | UPDATE | 승인 → partner_verified_users 삽입, 거절 → application 거절 |
| `on_application_approval` | event_applications | UPDATE/INSERT | approved/paid → event_participants 자동 발권 |
| `on_application_rejected` | event_applications | UPDATE | 거절 시 pg_net으로 payment-cancel Edge Function 호출 |
| `on_event_completed` | events | UPDATE | completed 시 settlement 자동 생성 |
| `on_storage_object_created` | storage.objects | INSERT | minglit_files 메타데이터 동기화 |
| `on_application_created` | event_applications | INSERT | 파트너 오너에게 file_access_grants 생성 |
| `on_event_reschedule` | events | UPDATE (end_time) | file_access_grants 만료일 갱신 |

### 6.2 RPC Functions

| Function | Purpose | Auth |
|----------|---------|------|
| `apply_event()` | 이벤트 신청 (성비 체크 → 신청 → 인증 제출) | SECURITY DEFINER |
| `check_party_balance()` | 성비 균형 체크 | SECURITY DEFINER |
| `get_event_ticket_balance_status()` | 티켓별 성비 상태 조회 | SECURITY DEFINER |
| `get_personalized_recommendations()` | pgvector 기반 추천 | SECURITY DEFINER |
| `get_events_within_radius()` | PostGIS 반경 검색 | SECURITY DEFINER |
| `get_bulk_eligibility_data()` | 유저 자격 일괄 조회 | SECURITY DEFINER |
| `get_matched_user_info()` | 매칭 상대 연락처 조회 | SECURITY DEFINER |
| `get_event_applications_with_user()` | 이벤트 신청 목록 + 유저 정보 | SECURITY DEFINER |
| `get_partner_members_with_user()` | 파트너 멤버 목록 + 유저 정보 | SECURITY DEFINER |
| `get_pending_verification_requests_with_user()` | 대기 인증 요청 목록 | SECURITY DEFINER |
| `get_entry_group_participant_counts()` | 입장 그룹별 참가자 수 조회 | SECURITY DEFINER |
| `search_events_pgroonga()` | 이벤트 전문 검색 | SECURITY INVOKER |
| `search_parties_pgroonga()` | 파티 전문 검색 | SECURITY INVOKER |

---

## 7. Cron Jobs

| Job Name | Schedule | Action |
|----------|----------|--------|
| `process-notifications` | 매분 (`* * * * *`) | `notification-worker` Edge Function 호출 (pg_net HTTP POST) |
| `send-event-reminders` | 매분 (`* * * * *`) | 이벤트 시작 55~65분 전 참가자에게 리마인더 (`produce_event`) |
| `settlement-status-transition` | 매일 03:00 (`0 3 * * *`) | 7일 경과 정산 `pending` → `ready` 전환 |

---

## 8. Matching System

양방향 투표 기반 매칭:

1. 파트너가 이벤트에 `match_rules` 설정 (source_group ↔ target_group)
2. 참가자가 `match_votes`에 투표 (voter → candidate)
3. 상대방도 투표하면 `handle_new_match_vote` 트리거 → `match_pairs` 자동 생성
4. 매칭된 상대의 연락처는 `get_matched_user_info()` (alias: `get_matched_user_contact()`) RPC로 접근

```text
User A ──vote──> User B
User B ──vote──> User A
         ↓
   match_pairs 생성 (user_lower_id < user_higher_id)
         ↓
   연락처 교환 가능 (RPC)
```

---

## 9. File Management

파일 접근 제어를 위한 2-tier 시스템:

1. **Storage Layer**: Supabase Storage → `storage.objects` (RLS로 업로드/조회 제어)
2. **Application Layer**: `minglit_files` + `file_access_grants` (세밀한 접근 권한)

파일 업로드 시 `on_storage_object_created` 트리거가 `minglit_files`에 메타데이터를 동기화한다.
이벤트 신청 시 `on_application_created` 트리거가 파트너 오너에게 자동으로 `file_access_grants`를 생성하며, 이벤트 종료 후 30일에 만료된다.

---

## 10. Error Handling & Monitoring

### Sentry Integration

`sentry_utils.ts`가 Edge Function 에러 트래킹을 담당한다:

- `initSentry()` — SENTRY_DSN 환경변수가 있을 때만 초기화 (없으면 no-op)
- `withSentry()` — `serve()` 패턴용 래퍼
- `withSentryHandler()` — `Deno.serve()` 패턴용 래퍼
- 환경 구분: `ENVIRONMENT` 환경변수 (local/dev/prod)
- `tracesSampleRate`: 0.2 (20%)

### Worker Error Handling

`worker_utils.ts`의 `WorkerUtils` 클래스:

- `isProcessed()` — `processed_events` 테이블로 중복 처리 방지
- `markProcessed()` — 처리 완료 기록
- `moveToDLQ()` — 실패 메시지를 `dead_letter_queue`로 이동 후 원본 큐에서 삭제
- `logTimeLag()` — 이벤트 발생~처리 지연 시간 로깅 (10초 초과 시 경고)

---

## 11. Environment & Configuration

환경변수는 `minglit_env/` private submodule로 관리:

```text
minglit_env/
├── local/          # 로컬 개발 (supabase start)
│   ├── flutter.env
│   ├── nextjs.env
│   └── supabase.env
└── dev/            # 데브 서버
    ├── flutter.env
    ├── nextjs.env
    └── supabase.env
```

Edge Function에서 사용하는 주요 환경변수:

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service Role 키 (RLS 우회) |
| `SENTRY_DSN` | Sentry 에러 트래킹 DSN |
| `ENVIRONMENT` | 환경 구분 (local/dev/prod) |
| `DENO_DEPLOYMENT_ID` | 프로덕션 배포 식별 (dev 함수 가드) |
| `PORTONE_API_SECRET` | Portone API 시크릿 |
| `IAMPORT_API_KEY` / `IAMPORT_API_SECRET` | Iamport API 키 |
| `OPENAI_API_KEY` | OpenAI 임베딩 API 키 |

---

## 12. Known Limitations

- **스키마 분리 미적용**: 모든 테이블이 `public` 스키마에 위치. payment/settlement 분리 계획 있음.
- **계좌번호 평문 저장**: `partner_settlements.account_number`가 암호화 없이 저장됨.
- **수수료 하드코딩**: PG 수수료 3.5%, 플랫폼 수수료 5%가 함수 내 하드코딩.
- **CAS/Version 미구현**: 정산 상태 변경에 낙관적 잠금(Optimistic Lock) 미적용.
- **RLS 복잡도**: 일부 정책이 다단 JOIN을 포함하여 성능 영향 가능성.
- **크론 해상도**: `pg_cron` 최소 1분 단위로, 실시간 처리에 한계.
- **신고(report) 시스템 미비**: 신고(report) 시스템은 기본 구현만 완료. 신고 처리 워크플로우(관리자 심사, 제재 등) 미구현.

---

## Related Documents

- [Client Architecture](./client.md) — Flutter 앱 아키텍처
- [Global Event Pipeline](./global-event-pipeline.md) — PGMQ 이벤트 파이프라인
- [Payment Pipeline](./payment-pipeline.md) — 결제/정산 파이프라인
- [Search & Recommendation](./search-and-recommendation.md) — PGroonga + pgvector
- [Trust & Verification](./trust-and-verification.md) — 2-layer 신뢰 모델
