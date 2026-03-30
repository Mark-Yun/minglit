# 회원 탈퇴(계정 삭제) — 기술 설계

## 아키텍처 원칙 요약

| 원칙 | 이 설계에서의 적용 |
|------|-------------------|
| Feature-first | `features/account_deletion/` 독립 피처 생성, 다른 피처 직접 import 없음 |
| Repository | `AccountRepository`에서만 Supabase/EF 호출. UI는 Repository만 호출 |
| Coordinator | `AccountDeletionCoordinator`가 모든 라우팅 담당. UI에서 GoRouter 직접 호출 없음 |
| Design System | `MinglitDialog`, `MinglitAlert`, `MinglitTextField` 등 기존 위젯 재사용 |

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 1 | DB 마이그레이션: `deleted_at` 컬럼 + 신규 테이블 3개 + RLS + 트리거 | `needs-dev`, `db-migration` | 없음 | 단일 migration 파일 |
| 2 | Edge Function: `user-delete-account` | `needs-dev`, `enhancement` | #1 | 재인증 + soft delete + 사유 저장 |
| 3 | Edge Function: `user-cancel-deletion` | `needs-dev`, `enhancement` | #1 | 유예 기간 취소 |
| 4 | CRON: `process-pending-deletions` + `cleanup-blocked-dis` | `needs-dev`, `enhancement` | #1, #2 | pg_cron 기반 |
| 5 | minglit_kit: `AccountRepository` + `AccountDeletionController` | `needs-dev`, `enhancement` | #2, #3 | shared 패키지 |
| 6 | 유저 앱: PrivacyPage 확장 + 탈퇴 플로우 UI | `needs-dev`, `enhancement` | #5 | 4개 화면 + coordinator |
| 7 | 파트너 앱: 탈퇴 플로우 UI | `needs-dev`, `enhancement` | #6 | 공유 위젯 재사용 |
| 8 | 유예 기간 재로그인 복구 다이얼로그 | `needs-dev`, `enhancement` | #5 | app_router redirect 로직 |
| 9 | RLS 업데이트: `deleted_at IS NOT NULL` 유저 검색/매칭 제외 | `needs-dev`, `db-migration` | #1 | 기존 RLS 정책 수정 |

## 수정 대상 파일

### 프론트엔드

#### 신규 파일 — shared (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| `minglit_kit/lib/src/data/models/deletion_status.dart` | `DeletionStatus` freezed 모델 (gracePeriodEnds, isPending) |
| `minglit_kit/lib/src/data/models/withdrawal_reason.dart` | `WithdrawalReason` freezed 모델 (reasonCode, reasonText) |
| `minglit_kit/lib/src/data/repositories/account_repository.dart` | `AccountRepository` — deleteAccount(), cancelDeletion(), getDeletionStatus(), reauthenticate() |
| `minglit_kit/lib/src/features/account_deletion/logic/account_deletion_controller.dart` | 탈퇴 플로우 상태 관리 Riverpod controller |

#### 신규 파일 — app_user

| 파일 | 변경 내용 |
|------|----------|
| `app_user/lib/src/features/account_deletion/ui/deletion_reason_page.dart` | Step 1: 탈퇴 사유 선택 |
| `app_user/lib/src/features/account_deletion/ui/deletion_info_page.dart` | Step 2: 탈퇴 안내 (삭제/보존 정보) |
| `app_user/lib/src/features/account_deletion/ui/deletion_verify_page.dart` | Step 3: 본인 확인 (비밀번호 / 소셜 재인증) |
| `app_user/lib/src/features/account_deletion/ui/deletion_complete_page.dart` | Step 5: 완료 화면 |
| `app_user/lib/src/features/account_deletion/logic/account_deletion_coordinator.dart` | 탈퇴 플로우 라우팅 coordinator |

#### 수정 파일 — app_user

| 파일 | 변경 내용 |
|------|----------|
| `app_user/lib/src/features/settings/privacy_page.dart` | 플레이스홀더 → 개인정보 설정 메뉴 (탈퇴 버튼 포함) |
| `app_user/lib/src/routing/app_routes.dart` | 탈퇴 관련 4개 라우트 추가 (`/my/privacy/delete/*`) |
| `app_user/lib/src/features/home/logic/home_coordinator.dart` | `pushAccountDeletion()` 메서드 추가 |
| `app_user/lib/src/routing/app_router.dart` | auth redirect에 `pending_deletion` 감지 로직 추가 (유예 기간 재로그인 복구 다이얼로그) |

#### 신규 파일 — app_partner

| 파일 | 변경 내용 |
|------|----------|
| `app_partner/lib/src/features/account_deletion/ui/` | app_user와 동일한 4개 화면 (공유 controller/repo 사용) |
| `app_partner/lib/src/features/account_deletion/logic/account_deletion_coordinator.dart` | 파트너용 coordinator |

#### 수정 파일 — app_partner

| 파일 | 변경 내용 |
|------|----------|
| `app_partner/lib/src/routing/app_routes.dart` | `/more/delete-account` 라우트 추가 |
| `app_partner/lib/src/features/more/more_coordinator.dart` | `pushAccountDeletion()` 메서드 추가 |
| `app_partner/lib/src/features/more/more_page.dart` | "회원 탈퇴" 메뉴 항목 추가 |

### 백엔드

#### DB 마이그레이션 (단일 파일)

**파일**: `supabase/migrations/YYYYMMDD000001_account_deletion.sql`

```sql
-- 1. user_profiles에 deleted_at 추가
ALTER TABLE public.user_profiles ADD COLUMN deleted_at timestamptz;

-- 2. withdrawal_reasons (익명 통계)
CREATE TABLE public.withdrawal_reasons (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  reason_code text NOT NULL,
  reason_text text,
  created_at timestamptz DEFAULT now()
);

-- 3. blocked_dis (DI 해시 기반 재가입 차단)
CREATE TABLE public.blocked_dis (
  di_hash text PRIMARY KEY,
  blocked_until timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 4. archived_records (법정 보존)
CREATE TABLE public.archived_records (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id_hash text NOT NULL,
  record_type text NOT NULL CHECK (record_type IN ('contract', 'payment', 'dispute', 'login')),
  record_data jsonb NOT NULL,
  retention_until timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 5. 인덱스
CREATE INDEX idx_archived_records_retention ON public.archived_records (retention_until);
CREATE INDEX idx_blocked_dis_until ON public.blocked_dis (blocked_until);
```

#### Edge Functions

**`supabase/functions/user-delete-account/index.ts`**

```
POST /functions/v1/user-delete-account
Auth: Bearer token 필수
Body: { reason_code?: string, reason_text?: string }

로직:
1. requireAuth() → user_id 확보
2. 서비스 롤로 user_profiles 조회 → deleted_at 확인 (이미 탈퇴 중이면 409)
3. 서비스 롤로 활성 예약/미정산 확인 → 있으면 400
4. user_profiles.deleted_at = now() 업데이트
5. withdrawal_reasons에 익명 사유 INSERT
6. Push 알림 구독 해제 (FCM 토큰 삭제)
7. Return { success: true, grace_period_ends: ISO8601 }
```

**`supabase/functions/user-cancel-deletion/index.ts`**

```
POST /functions/v1/user-cancel-deletion
Auth: Bearer token 필수

로직:
1. requireAuth() → user_id 확보
2. user_profiles 조회 → deleted_at이 없으면 404
3. user_profiles.deleted_at = null 복원
4. Return { success: true }
```

#### CRON Jobs (migration에 포함)

**`process-pending-deletions`** — 매일 09:00 KST (`0 0 * * *` UTC)

```
1. deleted_at >= 7일 경과한 유저 조회
2. 각 유저에 대해:
   a. 법정 보존 대상 데이터 → archived_records에 INSERT (user_id는 SHA-256 해시화)
   b. DI 해시 → blocked_dis에 INSERT (blocked_until = now() + 30일)
   c. auth.admin.deleteUser(userId) 호출 → cascade로 전체 정리
3. 처리 완료 로그
```

**`cleanup-blocked-dis`** — 매일 10:00 KST (`0 1 * * *` UTC)

```
DELETE FROM blocked_dis WHERE blocked_until < now();
```

#### RLS 정책 업데이트

기존 검색/매칭 관련 쿼리에 `WHERE deleted_at IS NULL` 조건 추가:

- `user_profiles` 읽기 정책: 본인이 아닌 경우 `deleted_at IS NULL` 필터
- 이벤트 참여자 목록 쿼리: `deleted_at IS NULL` 조건
- 매칭 대상 조회: `deleted_at IS NULL` 조건

#### 기존 테이블 참조 관계

탈퇴 시 cascade 삭제 대상 (auth.users → public 테이블):
- `user_profiles` (id → auth.users.id, ON DELETE CASCADE)
- `event_participants` (user_id)
- `social_interactions` (user_id 또는 target_user_id)
- `push_tokens` (user_id)
- `blocked_partners` (user_id 또는 partner_id)
- 기타 user_id FK가 있는 모든 테이블

> **검증 필요**: 모든 FK가 `ON DELETE CASCADE`로 설정되어 있는지 확인. `SET NULL`이나 `RESTRICT`가 있으면 마이그레이션에서 수정.

## 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| FK CASCADE 미설정 테이블 존재 | 중 | 구현 #1에서 모든 FK 제약조건 검사 후 필요시 ALTER |
| 소셜 재인증 플랫폼별 분기 복잡 | 중 | Google/Apple/Kakao 각각 기존 `signInWith*` 흐름 재사용, 재인증 로직은 EF에서 검증 |
| 7일 유예 기간 중 관련 데이터 무결성 | 낮음 | `deleted_at IS NOT NULL` 유저는 검색/매칭/이벤트 참여에서 자동 제외 (RLS + 앱 쿼리) |
| 법정 보존 데이터 아카이빙 누락 | 낮음 | CRON 내에서 트랜잭션으로 원자적 처리. 실패 시 재시도 |
| `archived_records.user_id_hash` 복원 불가 | 설계 의도 | 의도적 단방향 해시. 법정 보존은 통계/감사 목적이며 개인 식별 불가 |

## UX 리뷰 반영 사항 (#843)

| 항목 | 반영 위치 |
|------|----------|
| 버튼 높이 56px, 카드 라운딩 16px | 모든 탈퇴 화면의 버튼/카드 |
| 입력 필드 filled 스타일 | 사유 "기타" 입력 (MinglitTextField 사용) |
| 비표준 색상 → 토큰 + MinglitOpacity.tintFill | 경고/에러 컬러 |
| AppBar 타이틀 18px/w600 | 모든 탈퇴 화면 AppBar |
| 경고 텍스트 대비율 4.5:1 | 탈퇴 안내 페이지 경고 섹션 |
| 로딩 상태 | API 호출 시 `AsyncLoading` + CircularProgressIndicator |
| 다크 모드 | design token 기반이므로 자동 대응 |
| 소셜 재인증 실패 | 에러 스낵바 + 재시도 유도 |
| 이미 탈퇴 진행 중 화면 | app_router redirect에서 감지 → 복구 다이얼로그 |

## 의존성 방향

```
UI (features/account_deletion/ui/)
  ↓ (coordinator経由)
Coordinator (account_deletion_coordinator.dart)
  ↓ (controller経由)
Controller (minglit_kit/account_deletion_controller.dart)
  ↓ (repository経由)
Repository (minglit_kit/account_repository.dart)
  ↓ (HTTP)
Edge Functions (user-delete-account, user-cancel-deletion)
  ↓ (SQL)
DB (user_profiles, withdrawal_reasons, blocked_dis, archived_records)
```

UI → Coordinator → Controller → Repository → Edge Function → DB
모든 화살표는 단방향. 역방향 참조 없음.
