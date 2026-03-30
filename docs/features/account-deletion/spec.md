# 회원 탈퇴(계정 삭제) 스펙

## 개요

개인정보보호법 제36조/제37조 및 Apple/Google 앱스토어 정책에 의해 **앱 내 계정 삭제 기능은 필수**. 현재 개인정보처리방침에 "설정 > 계정 관리에서 탈퇴 가능"이라 고지했으나 미구현 상태로, 허위 고지에 해당.

### 핵심 원칙

1. **법적 필수 요건 충족**: 개인정보보호법 + 앱스토어 정책 모두 만족
2. **유저 자율성 존중**: 다크 패턴 없이 명확하고 빠른 탈퇴 경험 제공
3. **법정 보존 의무 준수**: 전자상거래법 등에 따른 거래 기록 분리 보관
4. **안전장치**: 진행 중인 예약/결제가 있으면 탈퇴 차단 (데이터 무결성)

### 참고 앱

| 앱 | 탈퇴 특징 | 밍릿 적용 |
|----|----------|----------|
| Bumble | 설정 > 삭제, 사유 수집(선택), 28일 복구 기간 | 7일 유예 기간 채택 |
| Hinge | 설정 > 삭제, 비밀번호 재확인, 즉시 삭제 | 비밀번호 재확인 채택 |
| 카카오 | 개인/보안에서 탈퇴, 손실 정보 상세 안내 | 손실 정보 안내 채택 |

---

## 구성 요소

### 1. 진입점

**유저 앱**: 마이페이지(`/my`) > 개인정보 설정(`/my/privacy`) > "회원 탈퇴" 버튼
**파트너 앱**: 더보기(`/more`) > (추후 계정 설정 메뉴) > "회원 탈퇴" 버튼

> 현재 `privacy_page.dart`가 "준비 중" 플레이스홀더 → 개인정보 설정 페이지로 확장하면서 탈퇴 버튼 추가.

### 2. 탈퇴 플로우 (유저 앱)

```
[개인정보 설정] → [탈퇴 사유 선택] → [탈퇴 안내] → [본인 확인] → [최종 확인 다이얼로그] → [완료]
```

#### Step 1: 탈퇴 사유 선택 (선택 사항)

화면: `AccountDeletionReasonPage`

- 라디오 버튼 목록 (단일 선택, 선택 안 해도 진행 가능)
- 사유 목록:
  1. 더 이상 사용하지 않아요
  2. 원하는 이벤트가 없어요
  3. 다른 서비스를 이용하고 있어요
  4. 개인정보가 걱정돼요
  5. 앱 사용이 불편해요
  6. 기타 (자유 입력, 최대 200자)
- "선택하지 않고 계속하기" 텍스트 버튼
- 수집된 사유는 `withdrawal_reasons` 테이블에 **익명화** 저장 (user_id 미저장, 통계 목적)

#### Step 2: 탈퇴 안내

화면: `AccountDeletionInfoPage`

상단에 경고 아이콘 (error 컬러) + "탈퇴하면 이런 것들이 사라져요"

**삭제되는 정보 목록:**
- 프로필 정보 (이름, 사진, 소개)
- 이벤트 신청 내역 및 매칭 기록
- 알림 설정 및 차단 목록
- 구매 내역 열람 권한

**보존되는 정보 (법정 의무):**

| 항목 | 근거 법령 | 보존 기간 |
|------|----------|----------|
| 계약/청약철회 기록 | 전자상거래법 | 5년 |
| 대금결제/공급 기록 | 전자상거래법 | 5년 |
| 소비자 불만/분쟁처리 기록 | 전자상거래법 | 3년 |
| 로그인 기록 | 통신비밀보호법 | 3개월 |

**추가 안내:**
- "탈퇴 후 7일간 계정이 유예 상태가 돼요. 이 기간에 다시 로그인하면 탈퇴가 취소돼요."
- "유예 기간이 지나면 계정이 영구 삭제되며 복구할 수 없어요."
- "같은 본인인증(DI) 정보로 30일간 재가입할 수 없어요."

#### Step 3: 본인 확인

화면: `AccountDeletionVerifyPage`

- 소셜 로그인 유저: 해당 소셜 계정으로 재인증 (Supabase `reauthenticate`)
- 이메일 로그인 유저: 비밀번호 입력

> 본인 확인을 통과해야 다음 단계 진행 가능.

#### Step 4: 최종 확인 다이얼로그

UX Writing 가이드 준수:
- 제목: "정말 탈퇴할까요?"
- 본문: "7일 유예 후 모든 데이터가 삭제되며 복구할 수 없어요."
- Primary: "탈퇴하기" (error 컬러 `#EF4444`)
- Secondary: "돌아가기"

#### Step 5: 완료 화면

- 체크 아이콘 + "탈퇴 요청이 완료됐어요"
- "7일 후 계정이 영구 삭제돼요."
- "그동안 밍릿을 이용해 주셔서 감사해요."
- 3초 후 자동으로 로그아웃 + 홈 화면으로 이동

### 3. 탈퇴 플로우 (파트너 앱)

파트너는 추가 조건이 있으므로 유저보다 엄격:

**탈퇴 전 차단 조건:**
- 미완료 이벤트가 있는 경우 (예정/진행 중 이벤트)
- 미정산 잔액이 있는 경우
- 진행 중인 환불 건이 있는 경우

차단 시 "탈퇴하기 전에 아래 항목을 먼저 해결해 주세요" + 항목별 바로가기 제공.

나머지 플로우(사유 수집 → 안내 → 본인 확인 → 최종 확인)는 유저 앱과 동일.

### 4. 유예 기간 (7일 Soft Delete)

| 상태 | 설명 |
|------|------|
| `pending_deletion` | 탈퇴 요청 직후. `deleted_at` 타임스탬프 기록 |
| 유예 기간 중 재로그인 | `deleted_at`을 null로 복원 → 탈퇴 취소 |
| 7일 경과 | CRON/스케줄러가 `auth.users` 삭제 → cascade로 전체 정리 |

**유예 기간 중:**
- 프로필이 다른 유저에게 보이지 않음 (검색/매칭에서 제외)
- 로그인 시 "탈퇴가 진행 중이에요. 취소할까요?" 다이얼로그 표시
- Push 알림 발송 중지

### 5. 재가입 방지

- DI (Duplicated Info) 기반으로 30일간 재가입 차단
- `blocked_dis` 테이블에 해시된 DI + 차단 만료일 저장
- 30일 경과 후 자동 삭제 (CRON)
- 재가입 시도 시: "탈퇴 후 30일이 지나야 다시 가입할 수 있어요. (N일 남음)"

### 6. 법정 보존 데이터 분리

탈퇴 실행(7일 후) 시:
1. 법정 보존 대상 데이터를 `archived_records` 테이블로 복사
2. 원본 테이블에서 cascade 삭제
3. `archived_records`에는 최소한의 식별 정보만 유지 (user_id 해시화)
4. 보존 기간 만료 후 `archived_records`에서도 삭제 (CRON)

---

## 데이터 소스

### 신규 Edge Function

**`user-delete-account`**
- Method: `POST`
- Auth: 필수 (Bearer token)
- Request Body: `{ reason_code?: string, reason_text?: string }`
- 동작:
  1. 진행 중 예약/미정산 확인 → 있으면 400 에러
  2. `user_profiles.deleted_at` = now() 설정
  3. 탈퇴 사유 익명 저장 (`withdrawal_reasons`)
  4. 푸시 알림 구독 해제
  5. Response: `{ success: true, grace_period_ends: "ISO8601" }`

**`user-cancel-deletion`**
- Method: `POST`
- Auth: 필수
- 동작: `user_profiles.deleted_at` = null

### 신규 CRON Job

**`process-pending-deletions`** (매일 1회)
1. `deleted_at`이 7일 이상 경과한 유저 조회
2. 법정 보존 데이터 아카이빙
3. DI를 `blocked_dis`에 기록
4. `auth.admin.deleteUser(userId)` 호출 → cascade 삭제

**`cleanup-blocked-dis`** (매일 1회)
- 만료된 DI 차단 레코드 삭제

### 신규 DB 테이블

```sql
-- 탈퇴 사유 (익명, 통계 목적)
create table public.withdrawal_reasons (
  id bigint generated always as identity primary key,
  reason_code text not null,
  reason_text text,
  created_at timestamptz default now()
);

-- 재가입 차단 (DI 해시)
create table public.blocked_dis (
  di_hash text primary key,
  blocked_until timestamptz not null,
  created_at timestamptz default now()
);

-- 법정 보존 아카이브
create table public.archived_records (
  id bigint generated always as identity primary key,
  user_id_hash text not null,
  record_type text not null,  -- 'contract', 'payment', 'dispute', 'login'
  record_data jsonb not null,
  retention_until timestamptz not null,
  created_at timestamptz default now()
);
```

### 기존 테이블 변경

```sql
-- user_profiles에 deleted_at 컬럼 추가
alter table public.user_profiles
  add column deleted_at timestamptz;
```

---

## 라우트 변경

### 유저 앱

| 변경 | 라우트 | 페이지 |
|------|--------|--------|
| 수정 | `/my/privacy` | `PrivacyPage` → 플레이스홀더에서 실제 개인정보 설정으로 확장 |
| 신규 | `/my/privacy/delete` | `AccountDeletionReasonPage` (Step 1: 사유) |
| 신규 | `/my/privacy/delete/info` | `AccountDeletionInfoPage` (Step 2: 안내) |
| 신규 | `/my/privacy/delete/verify` | `AccountDeletionVerifyPage` (Step 3: 본인 확인) |
| 신규 | `/my/privacy/delete/complete` | `AccountDeletionCompletePage` (Step 5: 완료) |

> Step 4(최종 확인)는 다이얼로그이므로 별도 라우트 불필요.

### 파트너 앱

| 변경 | 라우트 | 페이지 |
|------|--------|--------|
| 신규 | `/more/account/delete` | 동일한 탈퇴 플로우 (공유 위젯 사용) |

---

## 에러/로딩 상태

| 상황 | 처리 |
|------|------|
| 진행 중 예약 있음 | 탈퇴 차단 + 해결 필요 항목 목록 표시 |
| 미정산 잔액 있음 (파트너) | 탈퇴 차단 + 정산 페이지 바로가기 |
| 본인 확인 실패 | 인라인 에러 "비밀번호가 일치하지 않아요" / 소셜 재인증 실패 |
| 네트워크 에러 | "잠시 후 다시 시도해 주세요" 스낵바 |
| Edge Function 에러 | "탈퇴 처리 중 문제가 발생했어요. 다시 시도해 주세요." |
| 이미 탈퇴 진행 중 | "이미 탈퇴가 진행 중이에요. N일 후 삭제돼요." 안내 |

---

## 구현 이슈 분할 (예상)

| 순서 | 제목 | 의존성 |
|------|------|--------|
| 1 | DB 마이그레이션: `deleted_at` 컬럼 + 신규 테이블 3개 | 없음 |
| 2 | Edge Function: `user-delete-account`, `user-cancel-deletion` | #1 |
| 3 | CRON Job: `process-pending-deletions`, `cleanup-blocked-dis` | #1, #2 |
| 4 | 유저 앱 UI: PrivacyPage 확장 + 탈퇴 플로우 4화면 | #2 |
| 5 | 파트너 앱 UI: 탈퇴 플로우 (공유 위젯 재사용) | #4 |
| 6 | 유예 기간 중 재로그인 시 복구 다이얼로그 | #2, #4 |
| 7 | RLS 정책: `deleted_at IS NOT NULL` 유저 검색/매칭 제외 | #1 |
