---
source_url: https://github.com/Mark-Yun/minglit/issues/2038
captured_at: 2026-04-28
issue_number: 2038
state: open
labels: [audit-report, needs-tpm, P2-medium]
author: Mark-Yun
title: "⚖️ Audit (Legal): 마케팅 정보 수신 — 정보통신망법 §50 준수 가드 부재"
---

# ⚖️ Audit (Legal): 마케팅 정보 수신 — 정보통신망법 §50 준수 가드 부재

> Issue #2038 · open · created 2026-04-28 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2038

## Body

Scheduler: audit-legal-claude-subagents

## 요약

마케팅 정보 수신 동의(`marketing_consent`)는 회원가입과 설정 페이지에서 수집·철회 가능하지만, 실제로 광고성 푸시 알림을 발송하는 경로(`notification-worker`)에 **정보통신망법 §50 준수 가드가 전혀 없다**. 마케팅 카테고리(`notification_category` enum의 `'marketing'`)는 DB에 존재하나, EF/DB 어디에도 다음 의무가 강제되지 않는다:

1. **수신 동의 확인 의무** (§50 ①항)
2. **야간(오후 9시 ~ 오전 8시) 발송 차단** (§50 ⑤항 — 별도 동의 필수)
3. **"(광고)" 표기 + 수신거부 방법 명시** (§50 ④항)
4. **동의 후 2년마다 재확인 의무** (§50 ⑧항 / 시행령 §62의3)

마케팅 푸시가 본격적으로 도입되기 전에 **구조적 가드를 먼저 깔아야** 위반 위험이 차단된다. 운영팀이 카테고리 'marketing'으로 메시지를 큐잉하는 순간 위반이 시작된다.

---

## 증거

### 1. 마케팅 동의 토글은 있으나 발송 경로에서 사용 안 됨

- 동의 수집·철회: `apps/app_user/lib/src/features/settings/privacy_page.dart:81-85`
- DB 기록: `user_consents.consent_key = 'marketing_consent'` (`supabase/migrations/20260330000004_user_consents.sql:191`)
- 발송 EF: `supabase/functions/notification-worker/index.ts`
  - `sendFCM()` 직전에 `marketing_consent` 또는 `marketingConsent` 조회 코드 없음
  - `category` 필드는 `'service'`로 하드코딩되거나(Schema A, line 342) Schema B에서 외부에서 주입(line 365)

```bash
$ grep -nE "marketingConsent|marketing_consent" supabase/functions/notification-worker/index.ts
# (no output — 일치하는 줄 없음)
```

### 2. notification_category enum에 'marketing' 존재 → 운영팀이 사용 가능

`supabase/migrations/20260301000001_01_extensions_enums.sql:47`
```sql
create type public.notification_category as enum ('marketing', 'service', 'social');
```

운영팀이 큐에 `category: 'marketing'`로 push payload를 넣으면 동의 여부와 무관하게 발송된다.

### 3. 야간 시간 차단 / "(광고)" 표기 / 2년 재확인 모두 부재

```bash
$ grep -rnE "광고\)|야간|21:00|reconfirm|consent_anniversary" supabase apps --include="*.ts" --include="*.sql" --include="*.dart"
# (의미 있는 결과 없음 — 가드 코드 부재 확인)
```

`user_consents.consented_at`은 기록되지만, 가입 후 2년 경과 시 재동의를 강제하는 cron / EF / UI 플로우가 없다.

---

## 법적 근거

| 조항 | 의무 |
|------|------|
| **정보통신망법 §50 ①항** | 영리목적 광고성 정보를 전자적 전송매체로 전송 시 사전 수신자 동의 필수. 동의 없는 발송 시 **3천만원 이하 과태료** |
| **정보통신망법 §50 ④항** | 광고성 정보 전송 시 (1) 발신자 명칭, (2) 수신거부 방법, (3) "(광고)" 표기 (메시지 본문 또는 제목 첫 부분) 명시 |
| **정보통신망법 §50 ⑤항** | 오후 9시 ~ 다음날 오전 8시 광고성 정보 전송 시 **별도 사전 동의** 필요 |
| **정보통신망법 §50 ⑧항 (시행령 §62의3)** | 수신 동의 후 **2년마다 동의 유지 여부 확인**. 재확인 누락 시 동의 효력 상실 |
| **개인정보보호법 §22조 ②항** | 마케팅 동의는 다른 동의와 분리하여 별도 받음 (현재 signup_consent에서 분리됨 — 여기는 OK) |

---

## 영향도

- **현재 시점**: 운영 코드에서 marketing 카테고리 발송 사례 미확인 → 실 위반은 발생하지 않은 것으로 추정
- **위험 시점**: PM/마케팅팀이 프로모션 푸시를 큐잉하는 순간 자동 위반
- **과태료 규모**: 단발성 위반도 3천만원, 야간 발송은 별도 동의 위반으로 가중

P2 — 실 발송 전 가드 구축 필요. 마케팅 푸시 도입 일정에 따라 P1 승격 가능.

---

## 권장 조치

### 즉시 (P2)

1. **notification-worker에 발송 가드 추가**
   - `category === 'marketing'`인 페이로드는 `user_consents.marketing_consent` 또는 `user_settings.marketing_consent`가 `true`인 user에게만 발송
   - 동의 확인 실패 시 메시지를 **drop + log**, FCM 호출 자체를 막음
   - 위치: `supabase/functions/notification-worker/index.ts` Schema A/B 양쪽 분기

2. **야간 발송 차단**
   - 마케팅 카테고리에 한해, 한국 시간 오후 9시 ~ 오전 8시 발송 시도 시 **다음 오전 8시까지 큐 재예약**
   - PGMQ visibility timeout 활용 또는 별도 schedule 컬럼 추가
   - 단순 거부도 가능하나 프로모션 효과 손실 → 재예약 권장

3. **"(광고)" 표기 자동 prepend**
   - 마케팅 카테고리는 title 또는 body 앞에 `(광고)` 자동 prepend
   - 발송 후에도 `user_notifications`에 그대로 저장되어 감사 가능

### 단기 (P3)

4. **2년 재동의 cron**
   - `cleanup-retention` 또는 별도 EF에서 daily 체크
   - `consented_at < now() - interval '2 years'` AND `consent_key = 'marketing_consent'` AND `withdrawn_at IS NULL` → user에게 "동의 갱신" 푸시 + 7일 후 미응답 시 자동 withdraw
   - 알림 자체는 service 카테고리 (마케팅 동의 만료 안내는 광고 아님)

### 문서화

5. `docs/legal/retention-map.md`에 **광고성 정보 발송 가드 매트릭스** 추가
   - 의무 → 구현 위치 → 테스트 매핑
6. landing_user/privacy/page.tsx에 야간 시간·재동의 정책 명시 (현재는 누락)

---

## 인수 기준

- [ ] notification-worker가 `category='marketing'` 페이로드를 받으면 user의 marketing_consent를 조회하고, false면 drop
- [ ] 한국 시간 21:00–08:00 발송 시도는 차단 또는 재예약
- [ ] 마케팅 카테고리 메시지는 "(광고)" 접두어가 강제됨
- [ ] 동의 후 2년 경과 사용자에 대해 재확인 또는 자동 withdraw 처리
- [ ] pgTAP 또는 deno test로 위 4개 가드 모두 회귀 테스트 작성
- [ ] `docs/legal/retention-map.md`에 광고성 정보 가드 매트릭스 추가
