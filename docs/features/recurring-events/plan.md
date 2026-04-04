# 파트너 이벤트 반복 생성 (Recurring Events) — 기술 설계

## 개요

파트너가 반복 규칙(recurrence rule)을 설정하면 시스템이 최대 1개월 앞까지 이벤트를 자동 배치 생성한다.
기존 Party(템플릿) → Event(회차) 구조에 `recurrence_rules` 테이블을 추가하고, 크론잡이 매일 미생성분을 자동 생성한다.

**출처 이슈**: #1002, #1025

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 1 | DB: `recurrence_rules` 테이블 + `events` 컬럼 추가 | `enhancement` | 없음 | Migration + pgTAP + RLS |
| 2 | EF: `recurrence-rules` CRUD API | `enhancement` | #1 | 5개 액션 + Deno 테스트 |
| 3 | EF: `recurrence-cron` 배치 생성 크론잡 | `enhancement` | #1, #2 | pg_cron → pg_net → EF |
| 4 | Flutter: 이벤트 생성 화면 반복 설정 UI | `enhancement` | #2 | RecurrenceSettingsController + Section |
| 5 | Flutter: 반복 규칙 관리 화면 | `enhancement` | #2 | RecurrenceManagementController + Screen |
| 6 | Flutter: Repository + 모델 | `enhancement` | #2 | RecurrenceRule 모델 + Repository |

## 수정 대상 파일

### 백엔드 — DB Migration

| 파일 | 변경 내용 |
|------|----------|
| **신규** `supabase/migrations/20260406000001_recurrence_rules.sql` | `recurrence_rules` 테이블 생성, `events` 컬럼 추가, FK, CHECK, RLS, 크론잡 등록 |
| **신규** `supabase/tests/database/60_recurrence_rules_test.sql` | pgTAP: 스키마, FK, CHECK 제약조건 테스트 |
| **신규** `supabase/tests/database/61_recurrence_rules_rls_test.sql` | pgTAP: RLS 정책 테스트 |

### 백엔드 — Edge Functions

| 파일 | 변경 내용 |
|------|----------|
| **신규** `supabase/functions/recurrence-rules/index.ts` | CRUD API (create, update, pause, resume, cancel) |
| **신규** `supabase/functions/recurrence-rules/recurrence-rules_test.ts` | Deno 테스트 |
| **신규** `supabase/functions/recurrence-cron/index.ts` | 배치 생성 크론잡 EF |
| **신규** `supabase/functions/recurrence-cron/recurrence-cron_test.ts` | Deno 테스트 |

### 프론트엔드 — 모델/Repository (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `shared/packages/minglit_kit/lib/src/domain/models/recurrence_rule.dart` | RecurrenceRule 모델 (freezed) |
| **신규** `shared/packages/minglit_kit/lib/src/data/repositories/recurrence_rule_repository.dart` | CRUD + pause/resume/cancel |
| **신규** `shared/packages/minglit_kit/test/src/data/repositories/recurrence_rule_repository_test.dart` | Repository 테스트 |

### 프론트엔드 — 파트너앱 (app_partner)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `apps/app_partner/lib/src/features/party/logic/recurrence_settings_controller.dart` | 반복 설정 상태 관리 + 미리보기 날짜 계산 |
| **신규** `apps/app_partner/lib/src/features/party/ui/recurrence_settings_section.dart` | 반복 설정 UI 섹션 (ChoiceChip, FilterChip, DatePicker) |
| **신규** `apps/app_partner/lib/src/features/party/logic/recurrence_management_controller.dart` | 반복 관리 상태 (pause/resume/cancel) |
| **신규** `apps/app_partner/lib/src/features/party/ui/recurrence_management_screen.dart` | 반복 규칙 관리 화면 |
| `apps/app_partner/lib/src/features/party/ui/event_create_operation_tab.dart` | 반복 설정 섹션 추가 (일정 설정 → 반복 설정 → 티켓 사이) |
| `apps/app_partner/lib/src/features/party/ui/party_detail_screen.dart` | 이벤트 목록에 반복 아이콘(🔄) 표시 + 반복 관리 버튼 그룹(일시정지/규칙 수정/반복 해제) → RecurrenceManagementScreen 네비게이션 |
| `apps/app_partner/lib/src/routing/app_routes.dart` | `/more/parties/:partyId/recurrence` 라우트 추가 |
| **신규** `apps/app_partner/test/src/features/party/logic/recurrence_settings_controller_test.dart` | Controller 테스트 |
| **신규** `apps/app_partner/test/src/features/party/logic/recurrence_management_controller_test.dart` | Controller 테스트 |
| **신규** `apps/app_partner/test/src/features/party/ui/recurrence_settings_section_test.dart` | Widget 테스트 |
| **신규** `apps/app_partner/test/src/features/party/ui/recurrence_management_screen_test.dart` | Widget 테스트 |
| **신규** `apps/app_partner/test/goldens/recurrence_settings_section_golden_test.dart` | Golden 테스트: 반복 설정 섹션 (토글 OFF/ON, 미리보기) |
| **신규** `apps/app_partner/test/goldens/recurrence_management_screen_golden_test.dart` | Golden 테스트: 반복 관리 화면 (active/paused/cancelled 상태) |

## 설계 결정

### 1. `recurrence_rules` 테이블 스키마

```sql
CREATE TABLE recurrence_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id uuid NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
  pattern text NOT NULL CHECK (pattern IN ('weekly', 'biweekly', 'monthly')),
  days_of_week int[] NOT NULL DEFAULT '{}',
  month_day int CHECK (month_day >= 1 AND month_day <= 31),
  start_time time NOT NULL,
  end_time time NOT NULL,
  end_date date,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
  last_generated_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

`events` 테이블 확장:

```sql
ALTER TABLE events
  ADD COLUMN recurrence_rule_id uuid REFERENCES recurrence_rules(id) ON DELETE SET NULL,
  ADD COLUMN is_recurrence_exception boolean NOT NULL DEFAULT false;
```

**Party 1:1 제약**: 하나의 Party에 active/paused 규칙은 최대 1개만 허용한다.

```sql
CREATE UNIQUE INDEX uq_recurrence_rules_party_active
  ON recurrence_rules (party_id)
  WHERE status IN ('active', 'paused');
```

### 2. 중복 생성 방지

두 가지 방어 레이어:

1. **DB Unique Constraint**: `(recurrence_rule_id, start_time::date)` → 같은 규칙의 같은 날짜 이벤트 중복 INSERT 방지

```sql
CREATE UNIQUE INDEX uq_events_recurrence_date
  ON events (recurrence_rule_id, (start_time::date))
  WHERE recurrence_rule_id IS NOT NULL;
```

2. **EF 레벨**: `last_generated_date` 기반으로 이미 생성된 날짜 이후부터 생성 시작. INSERT 시 `ON CONFLICT DO NOTHING` 사용.

**근거**: 크론잡이 재실행되거나 resume 시 즉시 생성이 트리거되어도 중복이 발생하지 않아야 한다. DB 레벨 제약이 최종 방어선.

### 3. monthly "N번째 X요일" 패턴 인코딩

스펙에서 `month_day`가 null이면 "매월 N번째 X요일" 패턴이라고 정의했으나, N과 X를 저장할 컬럼이 없다.

**결정**: V1에서는 `month_day`(매월 N일) 패턴만 지원한다. "N번째 X요일" 패턴은 V2에서 `month_week_of`(int) + `month_day_of_week`(int) 컬럼을 추가하여 구현한다.

**근거**:
- V1 3가지 패턴(weekly, biweekly, monthly-날짜)만으로 페르소나 1, 2의 핵심 니즈를 충족한다.
- 페르소나 3("매월 마지막 토요일")은 `month_day`를 가장 가까운 토요일로 수동 설정하여 대응 가능하다.
- "마지막 N요일" 계산은 EF + Flutter 양쪽에 구현해야 하고, 월말 엣지케이스(2월 28/29일, 5번째 주 등)가 복잡하다.

### 4. 반복 규칙 EF를 별도 함수로 분리

**결정**: `recurrence-rules` EF를 신규 생성한다. `partner-manage-event`에 액션을 추가하지 않는다.

**근거**:
- `partner-manage-event`는 이미 create/update/update_status/update_tickets 4개 액션으로 비대하다.
- 반복 규칙은 이벤트 CRUD와 독립된 도메인이다 (Party 레벨 설정).
- 기존 패턴: 도메인별 EF 분리 (`partner-manage-party`, `partner-manage-event` 등).

### 5. 크론잡 구현 방식: pg_cron → pg_net → EF

**결정**: pg_cron이 pg_net으로 `recurrence-cron` EF를 HTTP POST 호출한다.

**대안 비교**:

| 방식 | 장점 | 단점 |
|------|------|------|
| pg_cron → SQL 직접 INSERT | 단순, 네트워크 불필요 | 템플릿 복제 로직(entry_groups, tickets 매핑)을 PL/pgSQL로 구현해야 함. 기존 EF 로직과 중복 |
| **pg_cron → pg_net → EF** | 기존 `partner-manage-event`의 템플릿 복제 로직 재사용 가능. 에러 핸들링/로깅 일관성 | 네트워크 호출 오버헤드 |

**근거**: `partner-manage-event`의 handleCreate() 로직에서 entry_group_templates → entry_groups ID 매핑 + ticket_templates → tickets의 target_entry_group_ids 리매핑이 핵심 복잡도이다. 이를 SQL로 재구현하면 유지보수 부담이 2배가 된다. EF 호출 방식이면 기존 로직을 공유 유틸로 추출하여 재사용할 수 있다.

### 6. 배치 생성 시 이벤트 파이프라인 연동

**결정**: 배치 생성된 이벤트는 기존 이벤트와 동일하게 파이프라인을 탄다.

- `events` INSERT → 기존 트리거/크론이 자동으로 상태 전환 (scheduled → active → ongoing → completed)
- 벡터 임베딩: 부모 Party의 `party_embeddings`가 이미 존재하므로, 개별 이벤트 임베딩 생성은 불필요
- 알림: `activate-upcoming-events` 크론이 scheduled → active 전환 시 알림을 트리거하므로, 배치 생성 시점에는 알림 없음

### 7. biweekly 격주 계산 기준

**결정**: 규칙의 `created_at` 날짜를 기준(reference date)으로 사용한다.

**로직**: `(target_date - created_at_date).inDays % 14 < 7`이면 "이번 주"로 판단.

**근거**: 별도 `reference_date` 컬럼 추가 없이 기존 `created_at`으로 충분하다. 규칙 수정 시에도 기준점이 변하지 않아 일관성 유지.

### 8. 규칙 생성 시 즉시 배치 생성

**결정**: `POST /parties/:id/recurrence-rules` 호출 시, 규칙 INSERT 후 즉시 1개월분 이벤트를 배치 생성한다.

**근거**: 크론잡은 매일 1회(UTC 00:00)만 실행되므로, 규칙 생성 직후 다음 크론까지 최대 24시간 공백이 생긴다. 즉시 생성으로 UX 일관성을 보장하고, 파트너가 미리보기에서 본 이벤트가 바로 노출된다.

### 9. update 시 `last_generated_date` 동작

**결정**: `update` 시 `last_generated_date`를 오늘 날짜로 리셋한다.

**로직**:
1. 규칙의 pattern/days_of_week/month_day/start_time/end_time/end_date 변경
2. `last_generated_date` → 오늘 날짜로 리셋
3. 이미 생성된 이벤트는 변경 없음 (spec: "이미 생성된 이벤트는 변경 없음")
4. 다음 크론 실행 시 오늘부터 1개월 범위에서 새 규칙 기반으로 미생성분 생성
5. 기존 이벤트와 새 규칙 기반 이벤트가 날짜 겹치면 unique index(`uq_events_recurrence_date`)로 중복 방지 → `ON CONFLICT DO NOTHING`

**근거**: 리셋하지 않으면 새 규칙이 반영되는 시점이 `last_generated_date` 이후로 밀려, 규칙 변경 직후 1개월 윈도우 내에서 이전 규칙으로 생성된 이벤트만 남고 새 규칙 이벤트가 없는 공백이 발생한다. 리셋 + ON CONFLICT DO NOTHING으로 기존 이벤트를 보존하면서 새 규칙 이벤트를 채운다.

### 10. resume 시 부족분 즉시 생성

**결정**: `POST /recurrence-rules/:id/resume` 호출 시, paused 기간에 미생성된 이벤트를 즉시 배치 생성한다.

**로직**:
1. `status` → `active`로 변경
2. `last_generated_date`부터 오늘 + 1개월까지 미생성 날짜 계산
3. 미생성분 즉시 INSERT

## 리스크 및 미결 사항

| 항목 | 심각도 | 설명 | 대응 |
|------|--------|------|------|
| 템플릿 복제 로직 공유 | Medium | `partner-manage-event`의 handleCreate()에서 entry_groups/tickets 복제 로직을 추출해야 함 | 공유 유틸 `copyPartyTemplateToEvent(supabase, partyId, eventId)` 분리 |
| events INSERT 트리거 부재 | Low | 현재 events INSERT 트리거가 없어 PGMQ 이벤트가 발행되지 않음. 배치 생성된 이벤트에 대한 검색 인덱스 갱신 누락 가능 | events는 party_embeddings를 통해 검색되므로 영향 없음. 단, V2에서 개별 이벤트 검색이 필요해지면 트리거 추가 검토 |
| 크론잡 실패 시 복구 | Medium | pg_net → EF 호출 실패 시 배치 생성 누락 | 크론잡 매일 실행 + idempotent 설계로 다음 날 자동 복구. Sentry 알림으로 실패 감지 |
| biweekly 기준 시점 | Low | `created_at` 기준이 직관적이지 않을 수 있음 | V1은 이 방식으로 시작. 유저 피드백에 따라 `reference_date` 컬럼 추가 검토 |

## 태스크 분배 (구현 단계용)

### Task 1: DB Migration + pgTAP (백엔드)

- `recurrence_rules` 테이블 생성 (위 스키마 참조)
- `events` 테이블 컬럼 추가 (`recurrence_rule_id`, `is_recurrence_exception`)
- Partial unique index: `uq_recurrence_rules_party_active`, `uq_events_recurrence_date`
- RLS 정책: 파트너가 자기 파티의 규칙만 CRUD 가능
- pg_cron 등록: 매일 UTC 00:00 `recurrence-cron` EF 호출
- moddatetime 트리거: `updated_at` 자동 갱신
- pgTAP 테스트: 스키마 존재, FK, CHECK, RLS

### Task 2: Edge Function — recurrence-rules CRUD

- `create`: 규칙 INSERT + 즉시 1개월분 배치 생성
  - 템플릿 복제 로직은 `partner-manage-event`에서 공유 유틸로 추출
- `update`: 규칙 수정 (미래 미생성분에만 영향)
- `pause`: status → paused
- `resume`: status → active + 부족분 즉시 생성
- `cancel`: status → cancelled (기존 이벤트 보존)
- 인증: `requirePartnerAuth()` — 파트너 JWT 필수
- Deno 테스트: happy path + 에러 + 멱등성

### Task 3: Edge Function — recurrence-cron 배치 생성

- pg_cron에서 호출되는 EF
- `recurrence_rules` WHERE `status = 'active'` 조회
- 각 규칙에 대해 `last_generated_date` ~ 오늘 + 1개월 범위에서 미생성 날짜 계산
- 날짜별 이벤트 INSERT (템플릿 복제 포함)
- `last_generated_date` 업데이트
- Deno 테스트: 패턴별 생성 건수, paused/cancelled 스킵, 중복 방지

### Task 4: Flutter — 모델 + Repository (minglit_kit)

- `RecurrenceRule` freezed 모델
- `RecurrenceRuleRepository`: EF 호출 래퍼 (create, update, pause, resume, cancel, get)
- Repository 테스트

### Task 5: Flutter — 이벤트 생성 화면 반복 설정 (app_partner)

- `RecurrenceSettingsController`: 토글, 패턴 선택, 요일 선택, 미리보기 날짜 계산
- `RecurrenceSettingsSection`: UI 위젯 (ChoiceChip, FilterChip, RadioListTile, 미리보기)
- `EventCreateOperationTab` 수정: 반복 설정 섹션 삽입
- Controller 테스트 + Widget 테스트

### Task 6: Flutter — 반복 규칙 관리 화면 (app_partner)

- `RecurrenceManagementController`: pause/resume/cancel 상태 전환
- `RecurrenceManagementScreen`: active/paused/cancelled 상태별 UI
- 라우트 등록: `/more/parties/:partyId/recurrence`
- Controller 테스트 + Widget 테스트
