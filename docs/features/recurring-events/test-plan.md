# 파트너 이벤트 반복 생성 (Recurring Events) — 테스트 보강 계획

## 계층별 테스트 계획

### Layer 1: Edge Function 테스트 (Deno)

| EF | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `POST /parties/:id/recurrence-rules` | `supabase/functions/recurrence-rules/recurrence-rules_test.ts` | happy path — 규칙 생성 + 1개월분 이벤트 배치 생성 | P1 |
| | | 필수 파라미터 누락 (pattern, days_of_week 등) → 400 | P1 |
| | | 유효하지 않은 pattern 값 (예: `'daily'`) → 400 | P1 |
| | | 존재하지 않는 party_id → 404 | P1 |
| | | weekly 패턴 — 4~5회 이벤트 생성 확인 | P1 |
| | | biweekly 패턴 — 2~3회 이벤트 생성 확인 | P1 |
| | | monthly 패턴 — 1회 이벤트 생성 확인 | P2 |
| | | end_date 지정 시 해당 날짜 이후 이벤트 미생성 | P1 |
| | | 1개월 윈도우 초과 이벤트 미생성 | P2 |
| | | 생성된 이벤트가 파티 템플릿(title, tickets, entry_groups) 복제 확인 | P1 |
| `PATCH /recurrence-rules/:id` | 동일 | pattern 변경 성공 | P1 |
| | | end_date 변경 성공 | P2 |
| | | 존재하지 않는 rule_id → 404 | P1 |
| `POST /recurrence-rules/:id/pause` | 동일 | status → `paused` 전환 | P1 |
| | | 이미 paused 상태 → 멱등성 (에러 없이 성공) | P2 |
| `POST /recurrence-rules/:id/resume` | 동일 | status → `active` 전환 + 부족분 이벤트 즉시 생성 | P1 |
| | | 이미 active 상태 → 멱등성 (에러 없이 성공) | P2 |
| `DELETE /recurrence-rules/:id` | 동일 | status → `cancelled` 전환 | P1 |
| | | 기존 생성 이벤트 보존 확인 (삭제되지 않음) | P1 |
| 크론잡 (배치 생성) | `supabase/functions/recurrence-cron/recurrence-cron_test.ts` | active 규칙에 대해 미생성 이벤트 배치 생성 | P1 |
| | | paused 규칙 건너뜀 | P1 |
| | | cancelled 규칙 건너뜀 | P1 |
| | | last_generated_date 기준 중복 생성 방지 | P1 |
| | | last_generated_date 업데이트 확인 | P2 |
| | | 이미 존재하는 날짜의 이벤트 중복 생성하지 않음 | P1 |

### Layer 2: Database 테스트 (pgTAP)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 스키마: `recurrence_rules` | `supabase/tests/database/60_recurrence_rules_test.sql` | `recurrence_rules` 테이블 존재 | P1 |
| | | 모든 컬럼 존재 (id, party_id, pattern, days_of_week, month_day, start_time, end_time, end_date, status, last_generated_date, created_at, updated_at) | P1 |
| | | `pattern` 값 CHECK 제약조건 (`weekly`, `biweekly`, `monthly`) | P2 |
| | | `status` 값 CHECK 제약조건 (`active`, `paused`, `cancelled`) | P2 |
| 스키마: `events` 확장 | 동일 | `recurrence_rule_id` 컬럼 존재 | P1 |
| | | `is_recurrence_exception` 컬럼 존재 (default: false) | P1 |
| FK 제약조건 | 동일 | `recurrence_rules.party_id` → `parties(id)` FK | P1 |
| | | `events.recurrence_rule_id` → `recurrence_rules(id)` FK | P1 |
| RLS | `supabase/tests/database/61_recurrence_rules_rls_test.sql` | 파트너가 자기 파티의 규칙만 조회 가능 | P1 |
| | | 다른 파트너의 파티 규칙 접근 불가 | P1 |
| | | 인증되지 않은 사용자 접근 차단 | P2 |

### Layer 3: Repository 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `createRecurrenceRule()` | `shared/packages/minglit_kit/test/src/data/repositories/recurrence_rule_repository_test.dart` | happy path — 규칙 생성 성공 + 반환값 검증 | P1 |
| | | Supabase 에러 → MingleException throw | P2 |
| `getRecurrenceRule(partyId)` | 동일 | happy path — 파티 ID로 규칙 조회 | P1 |
| | | 규칙 없음 → null 반환 | P2 |
| | | Supabase 에러 → MingleException throw | P2 |
| `updateRecurrenceRule()` | 동일 | happy path — 규칙 수정 성공 | P1 |
| | | Supabase 에러 → MingleException throw | P2 |
| `pauseRecurrenceRule()` | 동일 | happy path — status paused로 변경 | P1 |
| | | Supabase 에러 → MingleException throw | P3 |
| `resumeRecurrenceRule()` | 동일 | happy path — status active로 변경 | P1 |
| | | Supabase 에러 → MingleException throw | P3 |
| `deleteRecurrenceRule()` | 동일 | happy path — status cancelled로 변경 | P1 |
| | | Supabase 에러 → MingleException throw | P3 |

### Layer 4: Controller 테스트 (app_partner)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `RecurrenceSettingsController` | `apps/app_partner/test/src/features/party/logic/recurrence_settings_controller_test.dart` | 반복 토글 ON/OFF 상태 전환 | P1 |
| | | pattern 선택 (weekly → biweekly → monthly) | P1 |
| | | 요일 선택/해제 (days_of_week 업데이트) | P1 |
| | | 종료일 선택 (end_date 설정) | P1 |
| | | 종료 조건: 무기한 선택 시 end_date null | P2 |
| | | 미리보기 생성 — weekly 패턴 올바른 날짜 계산 | P1 |
| | | 미리보기 생성 — biweekly 패턴 올바른 날짜 계산 | P1 |
| | | 미리보기 생성 — monthly 패턴 올바른 날짜 계산 | P2 |
| | | 요일 미선택 상태에서 미리보기 빈 리스트 | P2 |
| `RecurrenceManagementController` | `apps/app_partner/test/src/features/party/logic/recurrence_management_controller_test.dart` | pause 액션 → 로딩 → 성공 상태 전환 | P1 |
| | | resume 액션 → 로딩 → 성공 상태 전환 | P1 |
| | | cancel 액션 → 로딩 → 성공 상태 전환 | P1 |
| | | pause 실패 → 에러 상태 | P2 |
| | | resume 실패 → 에러 상태 | P2 |
| | | cancel 실패 → 에러 상태 | P2 |

### Layer 5: Widget 테스트 (UI)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 반복 설정 섹션 | `apps/app_partner/test/src/features/party/ui/recurrence_settings_section_test.dart` | 토글 OFF → 반복 설정 UI 숨김 | P1 |
| | | 토글 ON → ChoiceChip(매주/격주/매월) 표시 | P1 |
| | | 매주 선택 → FilterChip(월~일) 요일 선택기 표시 | P1 |
| | | 매월 선택 → 요일 선택기 숨김 + 날짜 선택 표시 | P2 |
| | | 종료 조건 RadioListTile(무기한/종료일 지정) 표시 | P1 |
| | | 미리보기 리스트 — 생성될 날짜 목록 렌더링 | P1 |
| | | 요일 미선택 시 미리보기 빈 상태 표시 | P2 |
| 반복 관리 화면 | `apps/app_partner/test/src/features/party/ui/recurrence_management_screen_test.dart` | active 상태 → 일시정지/규칙 수정/반복 해제 버튼 표시 | P1 |
| | | paused 상태 → 재개/반복 해제 버튼 표시 | P1 |
| | | cancelled 상태 → 액션 버튼 비활성화 | P2 |
| | | 반복 해제 탭 → 확인 다이얼로그 표시 | P1 |
| | | 로딩 상태 → 버튼 비활성화 + CircularProgressIndicator | P3 |
| | | 에러 상태 → SnackBar 에러 메시지 | P3 |

### Layer 6: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| 반복 설정 섹션 | 토글 OFF (light/dark) | `apps/app_partner/test/goldens/recurrence_settings_section_golden_test.dart` | P2 |
| | 토글 ON — 매주 + 금요일 선택 (light/dark) | 동일 | P2 |
| | 미리보기 리스트 4건 표시 (light/dark) | 동일 | P3 |
| 반복 관리 화면 | active 상태 (light/dark) | `apps/app_partner/test/goldens/recurrence_management_screen_golden_test.dart` | P2 |
| | paused 상태 (light/dark) | 동일 | P3 |
| | cancelled 상태 (light/dark) | 동일 | P3 |

## 실행 순서

**P1 (필수): 40건**
- Edge Function CRUD happy path + 에러 (15건)
- Edge Function 크론잡 핵심 로직 (5건)
- pgTAP 스키마 + FK + RLS (8건)
- Repository happy path (6건)
- Controller 상태 전환 + 미리보기 생성 (6건)

**P2 (권장): 24건**
- Edge Function 추가 패턴 + 멱등성 (6건)
- pgTAP CHECK 제약조건 + RLS 추가 (3건)
- Repository 에러 핸들링 (3건)
- Controller 엣지 케이스 + 에러 상태 (6건)
- Widget 세부 상태 (3건)
- Golden 메인 변형 (3건)

**P3 (선택): 9건**
- Repository 에러 핸들링 추가 (3건)
- Widget 로딩/에러 상태 (2건)
- Golden 추가 변형 (3건)
- pgTAP 추가 검증 (1건)

**총 73건**
