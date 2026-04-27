# Payment Domain — 한국 PG 결제 + 정산 + 환불 모델

> minglit이 한국 결제 인프라 위에서 어떻게 결제·정산·환불을 처리하는지.
> 외부 SDK 변경 시 (PortOne v1 → v2 마이그레이션 등) 이 문서 참조.
> 마지막 업데이트: 2026-04-27 (코드 + audit reports 백필 시점)

---

## 1. 결제 채널 (PortOne 통합)

**PortOne V1 vs V2 현황:**

| 기능 | 버전 | 코드 위치 |
|------|------|----------|
| 일반 결제 (카드, 계좌이체 등) | V1 | `supabase/functions/payment-verify/index.ts`, `payment-cancel/index.ts` — `IamportClient` 사용 |
| 본인인증 (PASS) | V2 | `supabase/functions/identity-verify/index.ts` — `getPortoneClient()` (V2 SDK) 사용 |
| 정산 이체 (파트너 정산) | V2 | `supabase/functions/settlement-transfer/index.ts` — `portone.createOrderTransfer()` |

- **V1/V2 분기 결정 요인**: 의도적 마이그레이션이 아니라 **PG 계약에 따라 V1/V2 결정됨**. 현재 테스트 계정이 V1만 발급됨. 운영 PG 계약 시 V2 가능 여부 별도 검토 필요.
- **V1 사용**: 현재 테스트 환경 + 일부 PG (계약상 V1만)
- **V2 사용**: 본인인증 (identity-verify) 등 일부 영역
- **마이그레이션 계획**: PG 계약 갱신 시 V2 가능한 PG로 전환 검토. 강제 마이그레이션 X.

**결제 수단:** `<TODO: 실제 활성화된 결제 수단 목록 — 카드, 가상계좌, 토스페이, 네이버페이 등>`

**웹훅:**
- `supabase/functions/payment-webhook/index.ts`: PortOne → minglit 웹훅 수신
- V1 한계: HMAC 서명 없음 → IP whitelist(`x-forwarded-for`) 기반 검증만 사용 (보안 감사 #1487 P3 지적)
- 멱등성: `<TODO: PortOne 재시도 시 중복 처리 방지 구현 여부 — 보안감사 #1487에서 멱등성 가드 없음 지적>`

---

## 2. Payment Mode 분기

minglit은 두 가지 결제 모드를 지원. 이벤트 등록 시 파트너가 선택.

| 모드 | 결제 흐름 | 환불 | 정산 |
|------|---------|------|------|
| **플랫폼 결제** | 사용자 → minglit (PortOne V1) → 파트너 정산 (PortOne V2) | 자동 (2시간 내 / 이벤트 7일 전) | minglit 수수료 차감 후 파트너 이체 |
| **파트너 직접 결제** | 사용자 → 파트너 자체 채널 (현금/계좌이체/자체 PG) | 수동 (파트너 승인 필요) | minglit 개입 없음 |

**분리 이유:** 파트너마다 결제 인프라가 다름. 플랫폼 결제 강제 시 진입장벽 증가.

**파트너 결제 수단 등록:** `supabase/functions/partner-manage-settlement/index.ts`
- `upsert_bank_account` action으로 파트너 은행 계좌 등록
- 계좌번호: 하이픈/공백 제거 후 6~20자리 숫자 검증 (Fix #312)
- 파트너 정산 계좌 미등록 시: Hold 기간 후에도 송금 불가 → 파트너에게 알림 필요

---

## 3. 결제 흐름 (플랫폼 결제 상세)

### 3.1 결제 완료 흐름

```
사용자 앱
  → PortOne V1 SDK (결제 요청)
  → PortOne 결제 처리
  → 앱이 imp_uid + merchant_uid 수신
  → payment-verify Edge Function 호출
      1. requireAuth (호출자 JWT 검증)
      2. event_applications에서 주문 조회 (.select("payment_amount, status, user_id"))
      3. order.user_id !== auth → 403 Forbidden (Fix #1490: IDOR 방지)
      4. IamportClient.getPayment(imp_uid) → PortOne V1 API 조회
      5. payment.status === "paid" 확인
      6. payment.amount === order.payment_amount 금액 검증 (불일치 시 자동 취소)
      7. event_applications.status → "approved" 업데이트
```

### 3.2 웹훅 흐름

```
PortOne
  → payment-webhook (IP whitelist 검증)
  → pgmq "global_events" 큐에 이벤트 발행
  → event-matching Edge Function 처리
```

### 3.3 결제 상태 전이

`event_applications.status` 컬럼:
`pending` → `payment_failed` / `paid` → `pending_review` → `approved` / `rejected` / `cancelled`

---

## 4. 환불 정책

### 4.1 환불 정책 데이터 소스

환불 조건은 DB에 바이너리로 저장된 정책을 `get_current_policy('refund')` RPC로 동적 조회.
코드 하드코딩 없이 정책 변경 가능한 구조.

현행 정책 (코드에서 확인된 기본값):
- `grace_period_hours`: 2 (결제 후 2시간 이내 cooling off)
- `cutoff_days`: 7 (이벤트 시작 7일 전까지 환불 가능)

**히스토리:** 과거 이용약관(3일/50%/당일불가)과 코드(2시간/7일)가 불일치 → 약관을 코드 기준으로 통일 (PR #1144, Fix #1140, 전자상거래법 §17 준수).

### 4.2 플랫폼 결제 환불

| 조건 | 처리 |
|------|------|
| 결제 후 2시간 이내 | 자동 환불 (cooling off) |
| 이벤트 시작 7일 전 이내 결제 | 자동 환불 (청약철회) |
| 위 조건 외 | 환불 불가 → 고객센터(support@minglit.com) 안내 |
| 무료 이벤트 (payment_amount=0) | 이벤트 시작 전이면 취소만 (PortOne 환불 없음) |
| 이벤트 취소 (파트너) | 모든 참가자 자동 환불, minglit 수수료 포함 전액 환불 |

**환불 실행:** `supabase/functions/_shared/refund_utils.ts` — `executeRefund()` + `verifyRefundEligibility()` 공유 모듈. `payment-cancel`과 `user-cancel-order`에서 공용 사용 (Fix #299).

**처리 시간:** 전자상거래법 §18 — 3영업일 이내. PortOne 즉시 취소 API 호출로 처리.

### 4.3 파트너 직접 결제 환불

- 사용자가 파트너에 직접 연락 → 파트너 승인 후 환불
- 의도적 마찰 설계 (즉흥 환불 어렵게)
- `<TODO: 파트너 직접 결제 환불 시 한국 소비자 보호 법령 의무 — 어떤 약정 의무? 전자상거래법 §17 청약철회가 파트너 직접 결제에도 적용되는지>`

### 분쟁 시 minglit 책임 범위
- minglit은 **중개 플랫폼**이지 결제 당사자 X
- Partner 직접 결제 분쟁 (환불 거부, 정산 누락, 노쇼 분쟁 등) → **사용자와 Partner가 직접 처리**
- minglit은 운영 가이드 + 분쟁 신고 채널 제공만, 법적 책임 회피
- 이용약관 명시 필요: `<TODO: "Partner 직접 결제는 minglit이 중개만 한다" 조항 — 약관 어디에 어떻게>`

⚠️ **법적 위험**: 한국 통신판매중개업자도 일부 책임 부담 가능 (전자상거래법 §20-2). 변호사 자문으로 책임 한도 명확화 권장.

---

## 5. 정산 (Settlement) 모델

### 5.1 정산 흐름

```
이벤트 종료
  → Check-in 완료된 참가자 확인
  → settlement-query: 정산 대상 조회
  → settlement-register-transfers: PortOne에 이체 등록 (requireServiceRole)
  → settlement-transfer: PortOne createOrderTransfer 실행 (requireServiceRole)
  → payout-sync: 지급 동기화 (requireServiceRole)
  → reconciliation-daily: 일별 대사 (requireServiceRole)
```

**보안:** 정산 관련 Edge Function 전체 `requireServiceRole` 전용 (일반 유저 JWT 차단). 과거 `settlement-transfer`가 requireAuth만 사용한 취약점 Fix #1489로 수정.

### 5.2 수수료

- **수수료**: minglit **10% 정률**. 무료 이벤트는 수수료 없음 (0%). Partner 유형별 차등 없음 (모두 동일).

### 5.3 Hold 기간

- **14일** = 전자상거래법 청약철회 7일 + 운영 buffer 7일
- Hold 기간 중 환불 요청이 오면 정산 전 환불 처리

### 5.4 정산 Trigger 조건

- Check-in 완료된 참가자 결제건만 정산 산정 (No-show 미정산)
- 파트너 PortOne 파트너 ID(`portone_partner_id`) 등록 필수. 미등록 시 정산 진행 불가.

### 5.5 정산 송금 Cycle

- **Cycle**: 14일 Hold 종료 시 **자동 즉시 송금**. PortOne 정산 API를 통해 Partner 등록 계좌로 직접 입금. 별도 출금 신청 불필요 (Partner 입장에서 운영 부담 ↓)

### 5.6 PortOne 파트너 연동

- PortOne V2 파트너 정산 채널 사용
- `partners.portone_partner_id` 컬럼에 PortOne 파트너 ID 저장
- `partner-manage-settlement`에서 파트너 은행 계좌 등록 → PortOne 파트너에 매핑
- `<TODO: PortOne 파트너 정산에서 minglit 수수료 차감 방식 — PortOne 측에서 차감? 우리가 별도 계산?>`

---

## 5. 부가가치세 (VAT) — 단순 모델

minglit이 부가세 처리를 **다 떠안는** 단순 모델 (Partner 편의성 ↑):

- **Partner에게 송금**: 결제 총액에서 minglit 수수료 10% 제하고 나머지 송금 — VAT 분리 계산 X
- **사업자/비사업자 분기 X**: 사업자 등록 여부와 관계없이 동일 처리
- **이유**: Partner가 사업자 등록·세금계산서 발급·VAT 신고 등 운영 부담 ↓ → minglit 진입장벽 ↓

⚠️ **세무 위험 흡수 주의**: minglit이 VAT 부담 흡수 → 매출 인식·세무 신고에서 정확한 처리 필요. `<TODO: 세무사 자문 — 우리가 발생시키는 세금 의무 정확히 계산>`

---

## 7. 세무 — 결제 정보 보관

**한국 국세기본법:** 거래 정보 5년 보관 의무.
**전자상거래법 §6:** 계약/청약철회 5년, 소비자불만·분쟁처리 3년 보관.

**minglit 대응:**
- `event_applications`: `legal_min_days=1825` (5년), `enabled=false` (자동 파기 없음)
- `tickets`: `legal_min_days=1825`, `enabled=false`
- `ticket_templates`: `legal_min_days=1825`, `enabled=false`
- 파일: `supabase/migrations/20260422000003_payment_retention_protection.sql`
- 구조: `admin.retention_policies`의 `retention_above_legal_min` CHECK 제약으로 `retention_days >= legal_min_days` 보장

---

## 8. Edge Cases

| 케이스 | 현재 처리 |
|------|----------|
| **No-show** | Check-in 안 되면 Partner 정산 대상 X. **사용자 환불도 X** — 환불 신청 자체를 안 한 티켓은 환불 안 해줌. minglit은 No-show 결정 기준 없음 (Partner도 별도 No-show 기준 없음). |
| **부분 환불** | `executeRefund()`에 `amount` 파라미터 존재 → 부분 환불 가능. `<TODO: 실제 사용 케이스와 UI 존재 여부>` |
| **Chargeback** | `<TODO: 사용자가 카드사에 직접 분쟁 제기 시 처리 절차>` |
| **파트너 계좌 미등록** | `settlement-transfer` 에서 `portone_partner_id IS NULL` → 400 에러. 파트너 알림 별도 트리거 필요 (`<TODO: 알림 구현 여부>`) |
| **이벤트 취소 (파트너)** | `<TODO: 파트너가 이벤트 취소 시 전체 참가자 자동 환불 로직 코드 위치>` |
| **payment_amount=null (손상 데이터)** | `user-cancel-order`에서 명시적 400 에러 반환 (Fix #1652) |
| **결제 금액 위변조** | `payment-verify`에서 PortOne 조회 금액과 DB 금액 비교 → 불일치 시 자동 취소 |
| **중복 환불** | `refund_status !== 'none'` 체크로 차단 (`payment-cancel`, `user-cancel-order` 모두) |

### No-show 정책 명세

- **minglit 정책**: 참가 여부와 상관없이, 환불 요청 못 받은 티켓은 환불 X
- **No-show 결정 기준**: 없음 (Partner도 별도 기준 X)
- **이용약관 명시**: `<TODO: 약관 어느 조항? 이미 명시되어 있는지 확인>` **상태**: ❓ Mark 조사 필요. 현재 약관에 명시 여부 불명확. 미명시 시 법적 환불 분쟁에서 minglit/Partner에게 불리.
- **사용자 보호 메커니즘**: 환불 가능 윈도우 (결제 후 2hr / 이벤트 7일 전) 안에 신청 안 하면 = 자기 책임. 자동 환불 윈도우 알림 (`<TODO: 알림 발송 메커니즘 있는지>`)

---

## 9. PortOne SDK 통합 노트

> PortOne 공식 docs는 mirror하지 말고, 우리 통합 노트만 보존.

**V1 (일반 결제):**
- 클라이언트: `supabase/functions/_shared/iamport_client.ts`
- 사용 함수: `getPayment(imp_uid)`, `cancelPayment(imp_uid, reason)`
- 환경 변수: `PORTONE_API_KEY`, `PORTONE_API_SECRET`
- 웹훅: IP whitelist 기반 (`x-forwarded-for`). HMAC 미지원 (V1 한계).
- 알려진 이슈: 웹훅 재시도 시 멱등성 가드 없음 → 중복 pgmq_send 가능성 (보안감사 #1487 P3)

**V2 (본인인증 + 파트너 정산):**
- 클라이언트: `supabase/functions/_shared/portone_client.ts` — `getPortoneClient()`
- 본인인증: `portone.getIdentityVerification(identity_verification_id)`
- 파트너 정산: `portone.createOrderTransfer({ partnerId, paymentId, orderDetail })`
- 일반 결제 V2 전환: PG 계약 갱신 시 검토 예정. 현재 강제 마이그레이션 계획 없음.

**dev 환경 mock:**
- `supabase/functions/dev-mock-portone/`: dev 환경에서 PortOne을 mock하는 EF
- `iamport_client.ts:24-25`: `ENVIRONMENT` env var로 mock 전환. 내부 2차 게이트 없음 (보안감사 #1487 P3)

**Ed25519 QR 서명 (체크인):**
- QR 토큰은 Ed25519 서명. 현재 `event-checkin` EF에서 서명 검증을 클라이언트에 위임 (보안감사 #1487 P1-4, 이슈 #1491 진행 중)
- `user-get-ticket-token/index.ts:84`: 토큰 TTL 7일 — 단축 필요 (P3)

---

## Sources
- `supabase/functions/payment-verify/index.ts`
- `supabase/functions/payment-cancel/index.ts`
- `supabase/functions/user-cancel-order/index.ts`
- `supabase/functions/settlement-transfer/index.ts`
- `supabase/functions/partner-manage-settlement/index.ts`
- `supabase/functions/identity-verify/index.ts`
- `supabase/migrations/20260422000003_payment_retention_protection.sql`
- `supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql`
- 보안 감사: `docs/reports/security/2026-04-15-issue1487-*.md` (결제 소유권 검증, 정산 인가)
- 법률 감사: `docs/reports/legal/2026-03-29-issue0747-*.md` (환불 정책 약관-코드 불일치)
- 법률 감사: `docs/reports/legal/2026-04-21-issue1695-*.md` (전자상거래법 5년 보존 매핑)
