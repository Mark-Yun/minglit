# Trust & Verification

Minglit의 2-layer 신뢰 모델과 인증 시스템을 기술한다.
Identity(신원)와 Qualification(자격) 두 레이어로 나뉘며, 각각 플랫폼과 파트너가 검증 주체이다.

---

## 1. Overview

Minglit의 신뢰 모델은 다음 두 단계로 구성된다.

```text
Layer 1 (Identity): user_profiles.is_verified ← identity-verify ← PASS/SMS
Layer 2 (Qualification): user_verifications → verification_submissions → partner_verified_users
```

| 구분 | Layer 1: Identity | Layer 2: Qualification |
| :--- | :--- | :--- |
| 정의 | 실존 인물 + 나이/성별 확인 | 파티 참가 자격 (직장, 학력, 자산 등) |
| 데이터 | user_profiles (birth_date, gender, is_verified, ci, di) | user_verifications → verification_submissions → partner_verified_users |
| 검증 주체 | 플랫폼 (PASS/SMS API) | 파트너 (사람) |
| 특징 | 기본 자격, 즉시 필터링 | 추가 자격, 만료 가능 |

---

## 2. Layer 1 — Identity Verification

### 2.1 Flow
User App → Portone SDK → identity-verify → user_profiles 업데이트

### 2.2 Edge Functions
- `identity-verify`: Portone V2 API를 사용한다. `getIdentityVerification(identity_verification_id)` 호출 후 `status === "VERIFIED"` 임을 확인한다. `verifiedCustomer` 데이터를 추출하여 user_profiles의 name, birth_date, gender, phone_number, ci, di 필드를 업데이트하고 is_verified를 true로 설정한다.

> Note: 기존 `verify-identity-v1` (Iamport V1 API)은 삭제되었으며, Portone V2 기반 `identity-verify`로 통합되었다.

### 2.3 Key Fields
- **ci (Unique Key)**: 연계정보. 본인확인기관에서 부여하는 개인 식별 정보로, 중복 가입 방지에 사용된다.
- **di (Unique In Site)**: 중복가입확인정보. 특정 웹사이트 내에서 유저를 식별하기 위한 값이다.

---

## 3. Layer 2 — Qualification Verification

### 3.1 Lifecycle
```text
Partner: verifications 정의 (form_schema)
    ↓
User: user_verifications에 데이터 저장 (내 서랍)
    ↓
User: verification_submissions 제출
    ↓
Partner: 심사 (approve/reject/needs_correction)
    ↓
Trigger: partner_verified_users 생성 (승인 시)
```

### 3.2 Verification Categories
| Category | 설명 |
| :--- | :--- |
| career | 직장/경력 |
| asset | 자산/재산 |
| marriage | 결혼 상태 |
| academic | 학력 |
| vehicle | 차량 |
| etc | 기타 |

---

## 4. Database Schema

### 4.1 `verifications` table
인증 양식을 정의하는 테이블이다.

```sql
CREATE TABLE public.verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid REFERENCES public.partners(id) ON DELETE CASCADE,
  category verification_category NOT NULL,
  internal_name text NOT NULL,
  display_name text NOT NULL,
  description text,
  icon_key text,
  form_schema jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);
```

**form_schema example:**
```json
[
  {"type": "text", "label": "회사명", "key": "company_name", "required": true},
  {"type": "file", "label": "재직증명서", "key": "proof_file", "required": true}
]
```

### 4.2 `user_verifications` table
유저가 자신의 '서랍'에 저장해둔 인증 데이터다.

```sql
CREATE TABLE public.user_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  verification_id uuid NOT NULL REFERENCES public.verifications(id) ON DELETE CASCADE,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, verification_id)
);
```

### 4.3 `verification_submissions` table
실제 이벤트 신청 시 제출된 인증 데이터다.

```sql
CREATE TABLE public.verification_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id uuid NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  verification_id uuid NOT NULL REFERENCES public.verifications(id) ON DELETE CASCADE,
  application_id uuid REFERENCES public.event_applications(id) ON DELETE SET NULL,
  status verification_status NOT NULL DEFAULT 'pending',
  snapshot_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  admin_comment text,
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### 4.4 `partner_verified_users` table
파트너가 최종 승인한 유저들의 목록이다.

```sql
CREATE TABLE public.partner_verified_users (
  partner_id uuid NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  verification_id uuid NOT NULL REFERENCES public.verifications(id) ON DELETE CASCADE,
  submission_id uuid NOT NULL REFERENCES public.verification_submissions(id) ON DELETE CASCADE,
  verified_at timestamptz DEFAULT now(),
  valid_until timestamptz,
  PRIMARY KEY (partner_id, user_id, verification_id)
);
```

### 4.5 `verification_comments` table
심사 과정에서 파트너가 남기는 코멘트다.

```sql
CREATE TABLE public.verification_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL REFERENCES public.verification_submissions(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

---

## 5. Status Machine

`verification_status` enum: pending, approved, rejected, needs_correction, cancelled

```text
pending ──(파트너 승인)──> approved
pending ──(파트너 반려)──> rejected
pending ──(보완 요청)──> needs_correction
needs_correction ──(재제출)──> pending
* ──(유저 취소)──> cancelled
```

---

## 6. Key Trigger: on_submission_status_change

`handle_verification_approval()` 함수가 상태 변경을 처리한다.

- **On Approval**: `partner_verified_users`에 데이터를 INSERT 또는 UPSERT 한다. 연결된 `event_applications`의 상태를 'approved'로 업데이트한다.
- **On Rejection**: 연결된 `event_applications`의 상태를 'rejected'로 업데이트한다.
- **On Revocation**: 상태가 'approved'에서 다른 것으로 변경될 경우, `partner_verified_users`에서 해당 데이터를 DELETE 한다.

---

## 7. Event Pipeline Integration

`trigger_produce_event_verification()` 트리거가 작동한다.
상태가 approved, rejected, 혹은 needs_correction으로 변경될 때 `verification_result` 이벤트를 global queue에 생성한다. 이후 notification-worker가 이를 감지하여 유저에게 푸시 알림을 보낸다.

---

## 8. RLS Policies

| Table | Policy |
| :--- | :--- |
| verifications | Public read, Admin/Partner owner write |
| verification_submissions | User self read/create, Partner VERIFY_LIST_VIEW read, Partner VERIFY_REVIEW update |
| user_verifications | User self read/write |
| partner_verified_users | User self read |
| verification_comments | Multi-role read (Admin, Author, Submission user, Partner VERIFY_REVIEW), Partner VERIFY_REVIEW insert, Admin/Author update/delete |

---

## 9. Storage

- **Bucket**: `verification-proofs` (Private)
- **Path**: `{user_id}/applications/{event_id}/{file_name}`
- **Upload**: 본인 폴더에만 업로드 가능
- **View**: 본인, file_access_grants 권한 보유자, 파트너 및 관리자가 접근 가능

---

## 10. Event Application Integration

인증 시스템이 이벤트 신청 플로우와 연결되는 방식은 다음과 같다.

```text
User applies to event → event requires verification
  → verification_submissions created (application_id linked)
  → Partner reviews → on_submission_status_change trigger
  → Approval: event_applications.status → 'approved' → on_application_approval → event_participants 발권
  → Rejection: event_applications.status → 'rejected' → on_application_rejected → payment-cancel
```

---

## 11. Known Limitations

- **form_schema 유효성 검증 없음**: 서버 사이드 검증 없이 클라이언트 사이드에서만 수행된다.
- **valid_until 자동 만료 미구현**: `partner_verified_users`의 만료일이 지나도 자동으로 처리되지 않는다.
- **파일 증빙 삭제 정책 미정의**: 업로드된 증빙 파일의 보관 기간이나 삭제 시점이 정의되지 않았다.
- **인증 이력 관리 미구현**: 재인증 시 이전 기록을 덮어쓰며, 히스토리를 별도로 관리하지 않는다.

---

## Related Documents

- [Client Architecture](./client.md) — Flutter 앱 아키텍처 (Trust & Verification 개요)
- [Backend Architecture](./backend.md) — 전체 백엔드 인프라
- [Payment Pipeline](./payment-pipeline.md) — 결제/정산 (신청 거절 시 자동 환불)
- [Global Event Pipeline](./global-event-pipeline.md) — verification_result 이벤트 처리
