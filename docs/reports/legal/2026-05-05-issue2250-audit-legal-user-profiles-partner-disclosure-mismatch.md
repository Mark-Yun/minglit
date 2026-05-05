---
source_url: https://github.com/Mark-Yun/minglit/issues/2250
captured_at: 2026-05-05
issue_number: 2250
state: open
labels: [audit-report, bug, P1-high]
author: Mark-Yun
title: "⚖️ Audit (Legal): user_profiles 제3자 제공 — 개인정보처리방침 선언 ↔ 실제 제공 항목 불일치 (PIPA §17 위반)"
---

# ⚖️ Audit (Legal): user_profiles 제3자 제공 — 개인정보처리방침 선언 ↔ 실제 제공 항목 불일치 (PIPA §17 위반)

> Issue #2250 · open · created 2026-05-05 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2250

## Body

Scheduler: audit-legal-claude-subagents

## 핵심 결론

`user_profiles` 테이블의 신규 RLS(`Partners can read applicant profiles`, 20260505000001) + 기존 `select('*, user:user_profiles(*)')` join + 파트너 `EventApplicationDetailPage` 렌더링이 결합되어, **개인정보처리방침이 선언한 "이름(닉네임), 연령대, 자격 인증 정보"** 보다 **광범위한 개인정보가 파트너에게 실제로 제공**되고 있다.

이는 개인정보보호법 §17(제3자 제공 동의) 및 §30(개인정보처리방침 — 처리 사실과 일치 의무)에 정면 위반될 수 있다. 또한 PM 확정 결정(#1141 — "성별은 제외, 닉네임/연령대만")의 회귀이기도 하다.

## 발견 경위

이번 사이클(2026-04-29 ~ 2026-05-06) 머지된 PR #2164 / migration `20260505000001_user_profiles_partner_read_policy.sql` 검토 중 발견. 해당 PR은 RLS만 추가했고, "Flutter 코드 변경 없음 — 기존 join 쿼리가 이미 올바르게 작성되어 있고, RLS만 차단하고 있었음"으로 기재됨. 그러나 **그 기존 join 쿼리와 UI 렌더링이 #1141의 정책 결정과 일치하지 않는다.**

## 증거

### 1) RLS — column-level 제한 없음, 전체 row read 허용

`supabase/migrations/20260505000001_user_profiles_partner_read_policy.sql:9-18`

```sql
create policy "Partners can read applicant profiles" on public.user_profiles
  for select using (
    exists (
      select 1 from public.event_applications ea
      join public.events e on e.id = ea.event_id
      join public.parties p on p.id = e.party_id
      where ea.user_id = user_profiles.id
        and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
```

→ 정책은 row-level만 제한. `user_profiles`의 모든 컬럼(name, phone_number, birth_date, gender, ci_encrypted, di_encrypted, di_hash, profile_image_url 등)이 read 대상이 된다.

### 2) 클라이언트 SELECT — `*` 사용

`shared/packages/minglit_kit/lib/src/data/repositories/event_repository_application_queries.dart:82-86`

```dart
final response = await supabaseClient
    .from('event_applications')
    .select('*, user:user_profiles(*)')   // ← 모든 컬럼을 가져옴
    .eq('id', applicationId)
    .maybeSingle();
```

→ Postgrest가 RLS 통과한 모든 컬럼을 파트너 클라이언트에 평문 전송한다. Dart `UserProfile` 모델이 `ci/di/di_hash`를 무시한다 해도, **HTTP 응답 페이로드 자체에 노출**되므로 PIPA §29(안전조치) 측면에서도 부적절(파트너 단말 침해 시 leak 경로).

### 3) 파트너 UI — 실명·성별·정확한 생년월일 직접 노출

`apps/app_partner/lib/src/features/application/event_application_detail_page.dart:105-168`

```dart
final user = application.user;
final name = user?.name ?? '이름 없음';                 // ← 실명
final gender = switch (user?.gender) {
  'male' => '남',
  'female' => '여',
  _ => null,
};                                                       // ← 성별 표시
final birthDate = user?.birthDate;
...
if (birthDate != null)
  Text(
    '${birthDate.year}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.day.toString().padLeft(2, '0')}',
  ),                                                     // ← 정확한 생년월일 (YYYY.MM.DD)
```

### 4) 개인정보처리방침 선언

`apps/landing_user/src/app/privacy/page.tsx:127-133`

| 제공받는 자 | 제공 목적 | **제공 항목** | 보유 기간 |
|---|---|---|---|
| 모임 주최자(파트너) | 참여 승인 심사, 본인 확인, 출석 체크 | **이름(닉네임), 연령대, 자격 인증 정보(직업/소속 — 본인인증 완료 유저만)** | 이벤트 종료 후 30일 |

### 5) PM 확정 결정 — #1141 (CLOSED)

> ### 제3자 제공 항목 (파트너에게)
> - 이름(닉네임), 연령대(birth_year 기반), 자격 인증 정보(직업/소속 — 인증 유저만)
> - **성별은 제외** (현재 코드에서 미공유, 프라이버시 리스크)

→ **명시적으로 성별 제외 + 닉네임/연령대만**으로 좁힘. 현재 구현은 이 결정의 회귀.

## 영향 (Impact)

| 항목 | 선언 (privacy/페이지·#1141) | 실제 제공 (RLS+UI) | 위반 |
|---|---|---|---|
| 이름 | 닉네임 | **실명** (`user_profiles.name`) | §17(1)(3) 항목 불일치 |
| 연령 | 연령대 (birth_year 기반) | **YYYY.MM.DD 생년월일** | §17(1)(3) 항목 불일치 + §22-2 |
| 성별 | 제외 (PM 확정) | **남/여 표시** | §17(1)(3) 미고지 항목 제공 |
| 휴대폰번호 | 미선언 | RLS로 read 가능 (UI 미표시지만 응답 페이로드 포함) | §29 안전조치 |
| CI/DI 해시·암호문 | 미선언 | RLS로 read 가능 (응답 페이로드 포함) | §29 안전조치 |

### 법적 리스크

- **개인정보보호법 §17 (제공 동의)**: 동의받은 항목 외 제공은 위법.
- **개인정보보호법 §22-2 (최소수집·이용)**: 처리 목적 달성에 필요한 최소한으로 제한 의무.
- **개인정보보호법 §29 (안전조치 의무)**: 평문 PII가 권한 외 채널로 흐르지 않도록 기술적 조치.
- **개인정보보호법 §30 (개인정보처리방침)**: 방침과 실제 처리행위가 일치해야 함. 불일치 자체가 위반 + 행정처분 단골 항목.

## 권고 수정안 (코드 정정 — 권장)

### A) DB 계층: column-level 최소화

`partner_visible_user_profile` view 도입 (또는 `user_profiles` 직접 read 대신 RPC 사용):

```sql
create view public.partner_visible_user_profile as
select
  id,
  username,                                              -- 닉네임
  extract(year from birth_date)::int as birth_year,      -- 연령대 산출용
  is_verified,
  profile_image_url
from public.user_profiles;

-- RLS 동일 조건으로 view에 부여, user_profiles의 partner 정책은 revoke
```

또는 `select('user:user_profiles(...)')`을 RPC `get_application_with_partner_visible_user(uuid)`로 교체하여 컬럼을 서버에서 고정.

### B) 클라이언트 쿼리: explicit columns

`event_repository_application_queries.dart:84` 수정:

```dart
.select('*, user:user_profiles(id, username, birth_year, is_verified, profile_image_url)')
```

(view 도입 시) `.from('event_applications').select('*, user:partner_visible_user_profile(...)')`.

### C) 파트너 UI 정정

`event_application_detail_page.dart`:
- `user?.name` → `user?.username` (닉네임 표시)
- `gender` 블록 삭제 (#1141 결정 준수)
- `birthDate` 정확한 날짜 렌더 삭제. `birthYear` 기반 연령(`'$age세'`)만 표시 — 이미 line 113-115에 산출 코드 존재.

### D) Retention 정합성 검토

방침은 "이벤트 종료 후 30일"이지만 RLS·event_applications에는 시간 만료 predicate 없음. 다음 중 하나 적용:
- 이벤트 종료 30일 경과 후 partner의 read 차단 (RLS에 `e.ends_at + interval '30 days' > now()` 추가)
- 또는 retention_policies가 30일 시점에 파트너 가시 데이터를 anonymize/aggregate

(별도 이슈 #1695에서 retention 정책 매핑 공백이 다뤄졌음 — 그 후속과 연결 필요.)

### 회귀 테스트

- pgTAP: 파트너 권한으로 `select * from user_profiles ...`을 호출했을 때 phone_number/birth_date/ci_encrypted/di_encrypted/gender 컬럼이 view 또는 column grant로 차단되는지 검증.
- Flutter widget test: `EventApplicationDetailPage`가 실명/성별/full DOB를 렌더하지 않는지 회귀 가드.

## 우선순위 의견

**P1-high.** 운영 중인 데이터 처리에서 정책 선언과 실제 제공 항목이 어긋나 있으며, 개인정보보호위원회 행정처분에서 가장 빈번한 패턴 중 하나. 또한 #1141의 PM 결정에 대한 회귀이므로 테크니컬 백로그가 아닌 컴플라이언스 픽스로 처리해야 한다.

## 다음 단계 라우팅

`needs-tpm` — 트리아지 후 `needs-arch`/`needs-swe`로 라우팅 권장. RLS·view·repo·UI 4 계층을 모두 건드려야 하므로 SWE가 통합 PR로 처리하는 편이 적절.
