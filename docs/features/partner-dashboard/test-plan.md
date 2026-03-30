# 파트너 대시보드 리디자인 — 테스트 보강 계획

## 대상 코드

에픽 #516에서 신규/변경된 파일 기준.

## 테스트 계층별 계획

### Layer 1: Edge Function 테스트 (Deno)

| EF | 파일 | 테스트 케이스 | 우선순위 |
|----|------|-------------|---------|
| `partner-approve-application` | `partner_approve_application_test.ts` | 6건 | P1 |
| `partner-reject-application` | `partner_reject_application_test.ts` | 5건 | P1 |

#### partner-approve-application 테스트 케이스

```
1. approve — happy path: pending → approved, 응답 200 + {approved: 1}
2. approve — already processed: approved 상태 → 409 Conflict
3. approve — not found: 존재하지 않는 ID → 404
4. approve — no permission: 권한 없는 유저 → 403
5. bulk_approve — happy path: 이벤트의 모든 pending → approved, count 반환
6. bulk_approve — no pending: 대기 건 0 → {approved: 0}
```

#### partner-reject-application 테스트 케이스

```
1. reject — happy path: pending → rejected, rejection_reason 저장
2. reject — missing reason: 빈 사유 → 400
3. reject — already processed: approved 상태 → 409
4. reject — not found: → 404
5. reject — no permission: → 403
```

### Layer 2: Widget 테스트 (Flutter)

| 위젯 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `TodoSummaryChips` | `todo_summary_chips_test.dart` | 5건 | P2 |
| `EventActionCard` | `event_action_card_test.dart` | 8건 | P1 |
| `WeeklyStatsRow` | `weekly_stats_row_test.dart` | 3건 | P3 |
| `OnboardingStepGuide` | `onboarding_step_guide_test.dart` | 4건 | P2 |
| `EventApplicationManagePage` | `event_application_manage_page_test.dart` | 5건 | P2 |

#### TodoSummaryChips

```
1. 칩 3개 렌더링 (승인대기, 다가오는 이벤트, 준비 중)
2. count > 0 → 활성 색상, count == 0 → 회색
3. 승인대기 칩 탭 → onPendingTap 콜백
4. 다가오는 이벤트 칩 탭 → onUpcomingTap 콜백
5. 준비 중 칩 탭 → SnackBar "곧 출시"
```

#### EventActionCard

```
1. recruiting phase → "모집 중" 뱃지 + "신청 현황 보기" CTA
2. preparing phase → "준비 중" 뱃지 + "체크인 준비" CTA
3. live phase → "LIVE" 뱃지 + "체크인 계속하기" CTA (green)
4. ended phase → "종료" 뱃지 + "다음 회차 만들기" CTA
5. capacity bar 비율 표시 (60% → 0.6 progress)
6. 이벤트 없을 때 → EventActionCardEmpty 렌더링
7. EventActionCardEmpty: 파티 있음 → "이벤트 만들기", 파티 없음 → "파티 만들기"
8. onMainAction / onSecondaryAction 콜백 호출
```

#### WeeklyStatsRow

```
1. 매출/신청/체크인율 3칸 표시
2. change > 0 → 초록 "+N% ↑", change < 0 → 빨강 "N% ↓"
3. change == null → 변동률 숨김
```

#### OnboardingStepGuide

```
1. hasParty=false → 환영 메시지 + 2/4 진행률 + "첫 파티 만들기" CTA
2. hasParty=true → 3/4 진행률 + 파티 카드 + "첫 이벤트 만들기" CTA
3. onCreateParty 콜백 호출
4. onCreateEvent 콜백 호출
```

#### EventApplicationManagePage

```
1. 탭바 3개 렌더링 (대기중/승인됨/거절됨)
2. 이벤트별 그루핑 헤더 표시 (이벤트명, 날짜, 건수)
3. 인라인 승인 버튼 → EF 호출
4. 인라인 거절 버튼 → 다이얼로그 → 사유 입력 → EF 호출
5. 전체 승인 버튼 → 확인 다이얼로그 → 일괄 EF 호출
```

### Layer 3: 로직 테스트 (순수 함수)

| 함수 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `getEventPhase()` | `event_action_card_test.dart` | 5건 | P1 |
| `selectPrimaryEvent()` | `event_action_card_test.dart` | 6건 | P1 |

#### getEventPhase

```
1. 시작 4시간 후 → recruiting
2. 시작 2시간 후 → preparing
3. 시작 30분 전 (시작됨) → live
4. 종료 2시간 전 → ended
5. 정확히 3시간 경계 → preparing (< 3시간이므로)
```

#### selectPrimaryEvent

```
1. live 이벤트 우선 선택
2. live 없으면 preparing 선택
3. preparing 없으면 ended (24시간 이내) 선택
4. ended 없으면 recruiting (가장 빠른) 선택
5. 빈 리스트 → null
6. ended 24시간 초과 → 제외
```

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 파일 | 변형 | 우선순위 |
|------|------|------|---------|
| 홈 대시보드 | `home_dashboard_golden_test.dart` | 4건 | P2 |
| 온보딩 | `onboarding_golden_test.dart` | 2건 | P3 |
| 신청관리 | `application_manage_golden_test.dart` | 2건 | P3 |

#### 홈 대시보드 골든

```
1. recruiting 상태 홈 (라이트)
2. recruiting 상태 홈 (다크)
3. 빈 상태 홈 (이벤트 없음)
4. live 상태 홈
```

#### 온보딩 골든

```
1. 파티 생성 전 스텝 가이드
2. 파티 생성 후 이벤트 넛지
```

### Layer 5: pgTAP 데이터베이스 테스트

해당 없음 — 이번 에픽에서 DB 스키마 변경 없음. 기존 트리거 (`issue_ticket_on_approval`, `handle_application_rejection`)는 이미 테스트됨.

## 이슈 분할

| 순서 | 제목 | 테스트 수 | 우선순위 |
|------|------|----------|---------|
| 1 | test: getEventPhase + selectPrimaryEvent 순수 로직 테스트 | 11건 | P1 |
| 2 | test: partner-approve/reject-application EF 테스트 | 11건 | P1 |
| 3 | test: EventActionCard + TodoSummaryChips 위젯 테스트 | 13건 | P2 |
| 4 | test: OnboardingStepGuide + EventApplicationManagePage 위젯 테스트 | 9건 | P2 |
| 5 | test: 홈 대시보드 골든 테스트 | 4건 | P2 |

## 실행 순서

```
P1 (필수):  로직 테스트 11건 + EF 테스트 11건 = 22건
P2 (권장):  위젯 테스트 22건 + 골든 4건 = 26건
P3 (선택):  WeeklyStatsRow 3건 + 온보딩 골든 2건 + 신청 골든 2건 = 7건
────────────────────────────────────────
총 55건
```

## 참고

- 테스트 패턴: `docs/qa/AUTOMATION_TEST_GUIDE.md`
- Mock 유틸: `minglit_kit/test/helpers/supabase_mock_helpers.dart`
- Golden 헬퍼: `app_partner/test/utils/partner_golden_test_helpers.dart`
- EF 테스트 유틸: `supabase/functions/_test_utils/mock_http.ts`
