# 이벤트 수정/취소 — 테스트 계획

**관련 이슈**: #1592 (QA 계획) · #1396 (PM 스펙) · #1338 (통합 테스트 재활성화) · #1310 (Epic)
**스펙**: `docs/features/event-edit-cancel/spec.md`
**와이어프레임**: `docs/features/event-edit-cancel/wireframe.html`

이 문서는 이벤트 수정/취소 피처의 7-Layer 테스트 매핑이다.
구현 SWE는 각 구현 이슈 PR에 본 문서의 P1 케이스 중 해당 영역을 테스트로 추가해야 한다.

---

## 위험 영역 (구현 전 필독)

| 영역 | 위험 | 회귀 시 영향 |
|------|------|-------------|
| 유료 참가자 환불 | 환불 누락/중복 | 매출 손실, CS 폭증, 신뢰도 하락 |
| 정산 차감 | 차감 누락 또는 중복 차감 | 파트너 대금 분쟁 |
| 핵심정보 변경 알림 | 알림 누락 | 참가자 노쇼, "장소 모름" 컴플레인 |
| 정원 축소 | 현재 참가자 > 신정원 | 데이터 무결성 깨짐 |
| 동시 취소/체크인 | race — 체크인 중 취소 | 환불 불가 상태에서 환불 트리거 |
| 환불 실패 retry | retry 미작동 | 일부 참가자 환불 누락 |
| 취소 후 신규 신청 | RLS 미차단 | 취소된 이벤트 결제 발생 |

위 영역은 P1 이상 자동화 테스트 필수.

---

## 계층별 테스트 계획

### Layer 1: Edge Function 테스트 (Deno)

#### 1-1. `partner-manage-event` — `update` 액션 확장

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `supabase/functions/partner-manage-event/partner_manage_event_test.ts` (기존 파일에 추가) | 인증 없는 update 요청 → 401 | P1 |
| | EVENT_MANAGE 권한 없는 partner_member → 403 | P1 |
| | 부수 정보(title/description)만 변경 → 200 + 알림 미발행 | P1 |
| | 핵심 정보(start_time)만 변경 + `notify_changes: true` → PGMQ 이벤트 발행 1건 (event_modified) | P1 |
| | 핵심 정보(location_id) 변경 → PGMQ 이벤트 발행 (변경 필드 목록 포함) | P1 |
| | 핵심 정보 + 부수 정보 동시 변경 → 핵심 변경 1건만 알림 발행 | P1 |
| | `notify_changes: true`이지만 `previous_values` 누락 → 400 + "previous_values required" | P1 |
| | 핵심 정보 변경했지만 `notify_changes: false` → 알림 미발행 (드래프트 저장 케이스) | P2 |
| | `max_participants` < 현재 `current_participants` → 400 + "정원 부족" 에러 | P1 |
| | `max_participants` 증가 → 정상 200 (알림 미발행) | P1 |
| | `max_participants` 변경 없이 동일 값 전송 → 검증 통과 | P2 |
| | status가 `cancelled`/`completed`인 이벤트에 update → 400 "수정 불가" | P1 |
| | status가 `ongoing`인 이벤트에 update → 400 "진행 중 수정 불가" | P1 |
| | 다른 파티 소속 partner_member가 update → 403 (org scope 검증) | P1 |
| | `start_time` > `end_time` 검증 → 400 (기존 검증 유지) | P2 |
| | PGMQ 발행 실패 시 처리 — DB 트랜잭션 롤백 vs 부분 성공 (구현 결정 후 검증) | P1 |

#### 1-2. `partner-manage-event` — `update_status` 액션 확장

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| 동일 파일 | 인증 없는 update_status → 401 | P1 |
| | EVENT_MANAGE 권한 없는 member → 403 | P1 |
| | scheduled → cancelled (참가자 0명) → 200 + 환불 처리 0건 + 알림 0건 | P1 |
| | scheduled → cancelled (무료 참가자만) → 200 + 환불 0건 + 참가자 알림 N건 발행 | P1 |
| | scheduled → cancelled (유료 참가자 N명) → N건 환불 트리거 + 알림 N건 + 정산 차감 호출 1건 | P1 |
| | 환불 처리 중 PG 1건 실패 → 이벤트 상태는 cancelled로 전환 + 실패 환불은 retry 큐로 등록 | P1 |
| | 환불 전체 실패 → 이벤트 상태 롤백 vs cancelled 유지 (스펙 정책에 따른 검증) | P1 |
| | active → cancelled 허용 (Event State Machine #998 머지 후) | P1 |
| | ongoing → cancelled 시도 → 400 "진행 중 취소 불가" | P1 |
| | completed → cancelled 시도 → 400 | P1 |
| | cancelled → cancelled 재시도 (멱등성) → 200 (no-op) 또는 409 (정책에 따라) | P1 |
| | `cancel_reason` 없이 호출 → 정상 처리 (사유는 선택) | P2 |
| | `cancel_reason: insufficient_attendees` 포함 → events.metadata.cancel_reason 저장 확인 | P1 |
| | `cancel_reason: other` + `cancel_reason_text` → metadata에 함께 저장 | P2 |
| | 다른 파티 이벤트 cancel 시도 → 403 | P1 |
| | event_applications 전체 → status `cancelled`로 일괄 업데이트 (rejected와 구분) | P1 |
| | 동시에 동일 이벤트 cancel 2건 요청 (race) → 한쪽만 환불 처리, 다른쪽은 409 또는 no-op | P1 |
| | 신규 event_application INSERT → 취소된 이벤트는 RLS 또는 EF에서 차단 | P1 |

#### 1-3. 환불 retry 큐 (별도 worker EF — 스펙 §4 환불 실패 시 자동 재시도)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| 환불 retry worker (EF 명칭 미정) `_test.ts` | retry 큐에서 1건 pull → 환불 재시도 → 성공 시 status=`refunded` | P1 |
| | retry 3회 연속 실패 → DLQ 또는 admin 알림 트리거 | P1 |
| | retry 성공 후 참가자 알림 "환불이 완료됐어요" 발행 | P2 |
| | 이미 refunded 된 항목 재처리 차단 (멱등성) | P1 |

---

### Layer 2: Database 테스트 (pgTAP)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `supabase/tests/database/74_event_edit_cancel_schema_test.sql` (신규) | `events.metadata` JSONB 컬럼 존재 (기존 컬럼 재활용) | P1 |
| | `event_applications.status` CHECK 제약조건에 `cancelled` 값 포함 | P1 |
| | `event_applications.status = 'cancelled'`과 `'rejected'` 구분 가능 | P1 |
| `supabase/tests/database/75_event_edit_cancel_rls_test.sql` (신규) | 파트너: 자기 파티 이벤트만 update 가능 | P1 |
| | 파트너: 다른 파티 이벤트 update → RLS deny | P1 |
| | 파트너: 자기 파티 이벤트 update_status → cancelled 가능 | P1 |
| | 일반 유저: events UPDATE 불가 | P1 |
| | 일반 유저: 취소된 이벤트(status=cancelled)에 event_applications INSERT → 차단 | P1 |
| | 일반 유저: 활성(scheduled) 이벤트에 신청 INSERT → 정상 | P1 |
| `supabase/tests/database/76_event_cancel_cascade_test.sql` (신규) | 이벤트 status=cancelled 시 트리거로 event_applications 일괄 cancelled (구현 방식이 EF가 아닌 트리거인 경우) | P2 |
| | 트리거가 아니라 EF에서 처리하는 경우 — 본 테스트 파일 생략 | - |
| `supabase/tests/database/77_event_capacity_guard_test.sql` (신규 또는 기존 #68에 추가) | events.max_participants UPDATE 시 current_participants보다 작으면 트리거/CHECK로 거부 (DB 레벨 가드) | P1 |
| | DB 가드가 아니라 EF 검증인 경우 — Layer 1로 이관 | - |

> 정원 축소 가드는 EF에서 검증하는 것으로 충분하지만, race condition을 막으려면 DB 트리거 또는 advisory lock 권장. SWE가 구현 방식 결정 후 해당 레이어 테스트 추가.

---

### Layer 3: Repository 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `EventRepository.updateEvent()` | `shared/packages/minglit_kit/test/src/data/repositories/event_repository_commands_test.dart` (신규 또는 기존에 추가) | 필드 변경 없으면 EF 호출 안 함 (no-op) | P2 |
| | | 부수 정보만 변경 시 EF body에 `notify_changes: false` 포함 | P1 |
| | | 핵심 정보(시간/장소) 변경 시 EF body에 `notify_changes: true` + `previous_values` 포함 | P1 |
| | | EF 200 응답 → 업데이트된 Event 객체 반환 | P1 |
| | | EF 400 (정원 부족) → `MingleException` throw + 에러 메시지 전달 | P1 |
| | | EF 403 (권한 없음) → `MingleException` throw | P1 |
| | | 네트워크 에러 → `MingleException` throw | P2 |
| `EventRepository.cancelEvent()` | 동일 파일 | 기본 호출 (사유 없이) → EF body의 status=cancelled, cancel_reason 미포함 | P1 |
| | | `cancelReason: insufficient_attendees` 포함 호출 → EF body에 cancel_reason 포함 | P1 |
| | | `cancelReason: other` + `cancelReasonText` → EF body에 둘 다 포함 | P1 |
| | | EF 200 응답 → 취소된 Event 반환 (status=cancelled) | P1 |
| | | EF 400 (ongoing/completed) → `MingleException` + 에러 메시지 | P1 |
| | | EF 409 (이미 취소) → `MingleException` | P1 |
| | | 환불 부분 실패 응답(202 또는 200 + `refund_failed_count`) → 정상 반환 + 메타데이터 노출 | P1 |
| `EventRepository.getCriticalChangesDiff()` (편집 다이얼로그용 헬퍼) | 동일 파일 | 핵심 필드 변경 추출 (start_time, end_time, location_id) | P1 |
| | | 부수 정보 변경은 무시 | P1 |
| | | 변경 없으면 빈 리스트 | P2 |

---

### Layer 4: Controller / Coordinator 테스트

#### 4-1. `EventCreateController` — 편집 모드 분기

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/party/event/create/event_create_controller_test.dart` (기존 파일에 추가) | `eventId == null` → 생성 모드 (기존 동작 유지) | P1 |
| | `eventId != null` → 편집 모드 진입 + Repository.getEvent 호출 + 폼 프리필 | P1 |
| | 편집 모드 + 핵심 정보 변경 감지 → confirmDialog 트리거 상태 노출 | P1 |
| | 편집 모드 + 부수 정보만 변경 → confirmDialog 없이 바로 저장 | P1 |
| | 편집 모드 저장 → Repository.updateEvent 호출 + 성공 시 상태 업데이트 | P1 |
| | 저장 중 중복 호출 방지 (in-flight 상태에서 재호출 무시) | P2 |
| | 정원 축소 시 현재 참가자 수 초과면 인라인 에러 노출 + 저장 차단 | P1 |
| | EF 400 응답 → AsyncError 상태 + 에러 메시지 노출 | P1 |
| | 편집 모드에서 `party_id` 변경 시도 → 차단 (수정 불가 필드) | P2 |

#### 4-2. `EventDetailController` — 취소 액션

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/party/event/detail/event_detail_controller_test.dart` (기존 파일에 추가) | scheduled 이벤트: 취소 액션 활성화 | P1 |
| | active 이벤트: 취소 액션 활성화 (Event State Machine #998 머지 후) | P1 |
| | ongoing/completed/cancelled 이벤트: 취소 액션 비활성화 | P1 |
| | `cancel(reason)` 호출 → Repository.cancelEvent 호출 | P1 |
| | 취소 성공 → 상태 update (status=cancelled) + UI 갱신 신호 | P1 |
| | 취소 실패 (EF 400) → AsyncError 상태 + 에러 메시지 | P1 |
| | 취소 처리 중 중복 호출 방지 | P2 |

#### 4-3. `EventCreateCoordinator` — 편집 라우트

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/party/event/create/event_create_coordinator_test.dart` (기존 파일에 추가) | `EventEditRoute` 진입 시 eventId 파라미터 전달 | P1 |
| | 편집 저장 완료 → EventDetailRoute pop 또는 replace | P1 |
| | 편집 취소(폼 닫기) → 이전 화면 pop | P2 |

#### 4-4. 신규: `EventCancelCoordinator` (또는 EventDetailCoordinator 확장)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/party/event/detail/event_cancel_coordinator_test.dart` (신규) | `startCancel()` → 사유 선택 바텀시트 표시 | P1 |
| | 사유 선택 후 → 최종 확인 다이얼로그 표시 | P1 |
| | 최종 확인 → cancelEvent 호출 + 성공 시 EventDetailPage 새로고침 | P1 |
| | 사유 선택 → "돌아가기" → 바텀시트 닫기 | P2 |
| | 최종 확인 → "돌아가기" → 다이얼로그 닫기 | P2 |

---

### Layer 5: Widget 테스트 (UI)

#### 5-1. `EventCreatePage` — 편집 모드

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| EventCreatePage (편집 모드) | `apps/app_partner/test/src/features/party/event/create/event_create_page_test.dart` (기존 파일에 추가) | `eventId` 전달 시 폼 프리필 (제목/시간/장소/정원 등) | P1 |
| | | AppBar 제목 "이벤트 수정"으로 변경 (생성 모드 "이벤트 만들기"와 구분) | P1 |
| | | 핵심 정보 변경 + 저장 → 확인 다이얼로그 노출 (제목/변경내용 diff/참가자 수) | P1 |
| | | 부수 정보만 변경 + 저장 → 확인 다이얼로그 없이 진행 | P1 |
| | | 정원 < current_participants 입력 → 인라인 에러 "현재 참가자 N명보다 적은 정원으로..." | P1 |
| | | 저장 중 로딩 오버레이 + 버튼 비활성화 | P2 |
| | | 저장 실패 (네트워크) → SnackBar "저장에 실패했어요" | P2 |
| | | 권한 없음 (EVENT_MANAGE) 응답 → SnackBar "수정 권한이 없어요" | P2 |
| 핵심정보 변경 다이얼로그 | `apps/app_partner/test/src/features/party/event/create/critical_change_dialog_test.dart` (신규) | 변경 필드 diff 렌더링 (시작 시간 변경 표시) | P1 |
| | | 다중 핵심 정보 변경 시 모든 변경 항목 표시 | P1 |
| | | 참가 확정자 수 N명 표시 (0명일 때 다이얼로그 미표시 또는 다른 카피) | P1 |
| | | "변경하기" → 저장 confirm 콜백 호출 | P1 |
| | | "취소" → 다이얼로그 닫기 + 저장 취소 | P1 |
| | | Primary 버튼 색상 = `MinglitColors.primary` | P2 |

#### 5-2. `EventDetailPage` — 수정/취소 진입점

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| EventDetailPage AppBar | `apps/app_partner/test/src/features/party/event/detail/event_detail_page_test.dart` (신규 또는 추가) | scheduled 이벤트: 수정 아이콘 표시 + 더보기 메뉴 "이벤트 취소" 표시 | P1 |
| | | ongoing/completed: 수정 아이콘 비활성화 또는 숨김 | P1 |
| | | cancelled: "취소됨" 배지 표시 + 수정/취소 버튼 비활성화 | P1 |
| | | 수정 아이콘 탭 → EventEditRoute로 이동 | P1 |
| | | 더보기 → "이벤트 취소" 탭 → 취소 사유 바텀시트 노출 | P1 |
| | | EVENT_MANAGE 권한 없는 member: 수정/취소 버튼 미노출 | P1 |
| | | 참가자 0명: "이벤트 취소" 버튼 일반 스타일 | P2 |
| | | 참가자 1명+: "이벤트 취소" 버튼 error 스타일 (TextButton.error) | P2 |

#### 5-3. 취소 사유 바텀시트 + 최종 확인 다이얼로그

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| CancelReasonBottomSheet | `apps/app_partner/test/src/features/party/event/detail/cancel_reason_bottom_sheet_test.dart` (신규) | 4개 사유 라디오 렌더링 (인원 미달/개인 사정/장소 문제/기타) | P1 |
| | | 사유 선택 시 라디오 상태 변경 | P1 |
| | | "기타" 선택 시 자유 입력 필드 표시 (최대 200자) | P1 |
| | | "기타" 선택 + 빈 텍스트 → "다음" 활성화 (사유는 선택사항) | P1 |
| | | "선택 안 함"(돌아가기) → 바텀시트 닫기 + 콜백 미호출 | P1 |
| | | "다음" 탭 → 선택한 reason 코드 + text 콜백 전달 | P1 |
| CancelConfirmDialog | `apps/app_partner/test/src/features/party/event/detail/cancel_confirm_dialog_test.dart` (신규) | 참가자 0명: "참가 신청자가 없어..." 카피 표시 | P1 |
| | | 참가자 N명 (무료): 알림 N건 안내, 환불 안내 미표시 | P1 |
| | | 참가자 N명 (유료 M명): 알림 N건 + 환불 M명 + 환불 총액 표시 | P1 |
| | | 환불 총액 = 유료 참가자 결제금액 합계와 일치 | P1 |
| | | "이벤트 취소" 버튼 = `MinglitColors.error` | P1 |
| | | "이벤트 취소" 탭 → 콜백 호출 + 로딩 오버레이 진입 | P1 |
| | | "돌아가기" 탭 → 다이얼로그 닫기 | P1 |
| | | 취소 처리 중 뒤로가기 차단 (PopScope) | P2 |
| | | 환불 부분 실패 응답 → SnackBar "일부 환불이 지연되고 있어요" | P1 |

#### 5-4. 유저앱 — 취소된 이벤트 표시

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| EventDetailPage (user) | `apps/app_user/test/src/features/event/ui/event_detail_page_test.dart` (기존 파일에 추가) | status=cancelled 이벤트: "취소됨" 배지 표시 | P1 |
| | | 취소된 이벤트: 신청 버튼 숨김 또는 비활성화 | P1 |
| | | 취소된 이벤트: 취소 사유 표시 (있는 경우) | P2 |
| 검색/피드 (user) | 기존 검색/피드 화면 테스트에 추가 | status=cancelled 이벤트는 피드/검색 결과에서 제외 | P1 |
| 알림 — 이벤트 취소 푸시 수신 | `apps/app_user/test/src/features/notification/ui/notification_list_test.dart` (기존에 추가) | "이벤트가 취소됐어요" 알림 카드 렌더링 | P2 |
| 알림 — 핵심 정보 변경 푸시 수신 | 동일 | "이벤트가 변경됐어요" 알림 카드 렌더링 + 변경 항목 노출 | P2 |
| 마이티켓 (user) | `apps/app_user/test/src/features/my_tickets/ui/my_tickets_page_test.dart` (기존에 추가) | 취소된 이벤트 티켓: "취소됨" 상태 + 환불 진행 안내 | P1 |
| | | 환불 완료 시 "환불 완료" 라벨 표시 | P2 |

---

### Layer 6: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| EventCreatePage (편집 모드) | 핵심 정보 프리필 (light/dark) | `apps/app_partner/test/goldens/event_create_page_edit_golden_test.dart` (신규) | P2 |
| 핵심정보 변경 다이얼로그 | 시간 변경 단일 (light/dark) | `apps/app_partner/test/goldens/critical_change_dialog_golden_test.dart` | P2 |
| | 시간+장소 동시 변경 (light) | 동일 | P3 |
| EventDetailPage (파트너) | scheduled — 수정/취소 버튼 노출 (light/dark) | `apps/app_partner/test/goldens/event_detail_page_golden_test.dart` (기존 또는 신규) | P2 |
| | cancelled — 취소됨 배지 (light/dark) | 동일 | P2 |
| 취소 사유 바텀시트 | 미선택 / 기타 선택 + 입력 (light/dark) | `apps/app_partner/test/goldens/cancel_reason_bottom_sheet_golden_test.dart` | P2 |
| 취소 확인 다이얼로그 | 참가자 0명 / 무료 N명 / 유료 M명 (light/dark) | `apps/app_partner/test/goldens/cancel_confirm_dialog_golden_test.dart` | P2 |
| EventDetailPage (유저) | cancelled 이벤트 표시 (light/dark) | `apps/app_user/test/goldens/event_detail_page_cancelled_golden_test.dart` | P2 |
| 마이티켓 | 취소된 티켓 상태 (light/dark) | `apps/app_user/test/goldens/my_tickets_cancelled_golden_test.dart` | P3 |

---

### Layer 7: Integration 테스트 (다화면 플로우)

> `docs/qa/test-strategy.md` IT-P05 (party/event/ticket 편집)을 본 피처의 일부로 구현. #1338 재활성화의 일환.

| 테스트 ID | 시나리오 | 테스트 파일 | 스텝 | 우선순위 |
|-----------|---------|-----------|------|---------|
| IT-P05a | 이벤트 핵심정보 수정 → 알림 발행 검증 | `apps/app_partner/test/integration/cuj_event_edit_test.dart` (신규) | EventDetailPage → 수정 버튼 → EventCreatePage(편집) → 시간 변경 → 저장 → 확인 다이얼로그 → 변경하기 → EventDetailPage 복귀 + Mock PGMQ에 event_modified 메시지 1건 검증 | P1 |
| IT-P05b | 이벤트 부수정보 수정 → 알림 미발행 | 동일 | 제목 변경 → 저장 → 다이얼로그 미표시 → Mock PGMQ 0건 | P1 |
| IT-P05c | 이벤트 정원 축소 거부 | 동일 | 정원 입력 < current_participants → 인라인 에러 노출 → 저장 차단 | P1 |
| IT-P06a | 참가자 0명 이벤트 취소 (간단 플로우) | `apps/app_partner/test/integration/cuj_event_cancel_test.dart` (신규) | EventDetailPage → 더보기 → 이벤트 취소 → 사유 바텀시트(돌아가기 가능) → 다음 → 확인 다이얼로그(환불/알림 안내 없음) → 이벤트 취소 → Mock EF 호출 + 상태 cancelled | P1 |
| IT-P06b | 유료 참가자 N명 이벤트 취소 (전액 환불) | 동일 | 사유=`insufficient_attendees` → 확인 다이얼로그(환불 총액 표시) → 이벤트 취소 → Mock 환불 N건 트리거 + Mock 알림 N건 발행 + 상태 cancelled + 정산 차감 1건 | P1 |
| IT-P06c | 환불 1건 실패 시 retry 큐 등록 | 동일 | Mock PG에서 1건 실패 → 이벤트는 cancelled로 전환 + 실패 1건 retry 큐 등록 + SnackBar "일부 환불 지연" 노출 | P1 |
| IT-U06a | 유저: 취소된 이벤트 표시 (마이티켓) | `apps/app_user/test/integration/cuj_cancelled_event_view_test.dart` (신규) | 마이티켓 진입 → 취소된 이벤트 카드 → "취소됨" 배지 + 환불 상태 안내 | P1 |
| IT-U06b | 유저: 취소된 이벤트 신규 신청 차단 | 동일 (또는 검색 통합 테스트에 추가) | 검색 결과에서 cancelled 이벤트 제거 확인 | P2 |

#### 통합 테스트 환경 가정

- Mock PGMQ: `IntegrationTestHarness.mockPgmq()`로 발행된 메시지 누적 검증
- Mock 환불 PG: `MockPaymentService`로 환불 호출/응답 시뮬레이션 (성공/실패 시나리오)
- Mock Edge Function: `MockSupabaseClient`로 EF 응답 시뮬레이션 (실제 EF 호출 X — pgTAP/EF 단위테스트와 분리)

---

### Layer 8: 회귀 검증 (기존 테스트 영향)

| 기존 테스트 | 검증 포인트 |
|-----------|-----------|
| `partner_manage_event_test.ts` 전체 | update / update_status 기존 케이스 회귀 통과 |
| `event_detail_controller_test.dart` 전체 | 취소 액션 추가 후 기존 detail 로직 회귀 통과 |
| `event_create_controller_test.dart` 전체 | 편집 모드 분기 추가 후 생성 모드 기존 케이스 회귀 통과 |
| 기존 RLS 테스트 (event_applications) | 신규 cancelled status 추가 후 기존 RLS 정책 통과 |
| `apps/app_partner/test/integration/cuj_onboarding_to_event_test.dart` (IT-P01) | 이벤트 생성 플로우 회귀 통과 (편집 모드 분기가 생성 흐름을 깨지 않음) |
| 기존 MyTickets 테스트 (app_user) | cancelled status 처리 추가 후 기존 티켓 표시 회귀 통과 |

---

## 핵심 엣지 케이스 매트릭스

각 레이어에 분산되어 포함되어야 하는 우선 엣지 케이스:

| 엣지 케이스 | 해당 레이어 | 우선순위 |
|-----------|-----------|---------|
| 동시 취소 요청 (race): 같은 이벤트 동시 cancel 2건 | Layer 1 (EF) | P1 |
| 정원 축소 race: max_participants UPDATE 도중 신규 신청 INSERT | Layer 1 + Layer 2 | P1 |
| 환불 부분 실패: PG 8건 중 2건 실패 | Layer 1 + Layer 5 (UI 알림) + Layer 7 (IT) | P1 |
| 환불 retry 멱등성: 이미 refunded 항목 재시도 | Layer 1 (retry worker) | P1 |
| 핵심 정보 + 부수 정보 동시 변경: 알림은 핵심 정보만 트리거 | Layer 1 + Layer 4 + Layer 7 | P1 |
| 이벤트 status 전환 race: scheduled→ongoing 동시에 cancel 시도 | Layer 1 | P1 |
| 취소 후 신규 신청 차단: RLS / EF 어디에서 차단되는지 명확히 | Layer 1 + Layer 2 | P1 |
| `cancel_reason_text` 200자 경계: 199/200/201자 | Layer 1 | P3 |
| 참가자 0명: 환불/알림 단계 모두 스킵 | Layer 1 + Layer 5 + Layer 7 | P1 |
| 무료 이벤트만 (유료 0): 환불 스킵 + 알림만 | Layer 1 + Layer 7 | P1 |
| 정산 차감 멱등성: 같은 cancel 이벤트 정산 차감 2번 호출 | Layer 1 (정산 EF 호출) | P1 |
| Event State Machine #998 미머지 시: active → cancelled 호출 케이스 분기 | Layer 1 (조건부 활성화) | P2 |

---

## 실행 순서 및 카운트

**P1 (필수): 95건**
- Layer 1 EF (update + update_status + retry): 35건
- Layer 2 pgTAP (schema/RLS): 8건
- Layer 3 Repository (updateEvent/cancelEvent/diff): 12건
- Layer 4 Controller/Coordinator: 17건
- Layer 5 Widget: 18건
- Layer 7 Integration: 5건

**P2 (권장): 30건**
- Layer 1 EF 추가 케이스: 4건
- Layer 3 Repository 네트워크/노옵: 3건
- Layer 4 Controller 중복호출/로딩: 3건
- Layer 5 Widget 세부 (스타일/로딩/SnackBar): 8건
- Layer 6 Golden 메인 화면: 8건
- Layer 7 Integration 추가: 1건
- 기타 엣지: 3건

**P3 (선택): 8건**
- Layer 1 EF 경계값: 1건
- Layer 6 Golden 추가 변형: 5건
- 마이티켓 환불완료 라벨: 2건

**총 133건**

---

## 구현 이슈 매핑

스펙의 "구현 이슈 분할" 7개 이슈와 본 테스트 계획의 매핑:

| 구현 이슈 | 필수 테스트 (P1) | 비고 |
|----------|----------------|------|
| 1. EF: update_status 취소 + 환불 + 알림 | Layer 1 §1-2 (17건) + Layer 2 §RLS (4건) | 환불 retry 큐는 별도 worker로 분리 가능 |
| 2. EF: update 시 핵심 정보 변경 알림 | Layer 1 §1-1 (16건) + Layer 2 §schema (3건) | |
| 3. Flutter: EventEditRoute + EventCreatePage 편집 모드 | Layer 4 §4-1 (8건) + Layer 4 §4-3 (2건) + Layer 5 §5-1 (12건) | |
| 4. Flutter: EventDetailPage 수정/취소 진입점 + 취소 UI | Layer 4 §4-2 (6건) + Layer 4 §4-4 (3건) + Layer 5 §5-2 (5건) + Layer 5 §5-3 (12건) | |
| 5. Flutter: EventRepository updateEvent/cancelEvent | Layer 3 (12건) | |
| 6. Flutter: 유저앱 취소 이벤트 "취소됨" 표시 | Layer 5 §5-4 (5건) | |
| 7. 테스트: 이벤트 수정/취소 통합 테스트 (#1338 재활성화) | Layer 7 (5건) + Layer 8 회귀 (전체) | 다른 6개 이슈 머지 후 마지막에 진행 |

---

## SWE 체크리스트 (PR 리뷰 시 확인)

- [ ] 본인 구현 이슈에 매핑된 P1 테스트가 모두 추가되었는가?
- [ ] 회귀 검증 (Layer 8) — 기존 테스트가 모두 통과하는가?
- [ ] 환불/정산 관련 변경 시: 멱등성 + race 케이스 자동화 테스트 포함했는가?
- [ ] 핵심정보 변경 알림 PGMQ 발행: 단위 테스트 + IT 양쪽에서 검증했는가?
- [ ] 권한 (EVENT_MANAGE) 검증: EF + UI 양쪽에 테스트 있는가?
- [ ] PR 본문에 본 문서의 어떤 케이스를 커버했는지 명시했는가?

---

## QA 게이트 (머지 전 확인)

- **#1338 재활성화 PR (구현 이슈 7번)** 머지 시:
  - IT-P05a/b/c, IT-P06a/b/c, IT-U06a 모두 통과 필수
  - 환불 부분 실패 시나리오 (IT-P06c) 결정적 동작 보장
  - 기존 IT-P01 (파트너 온보딩→이벤트 생성) 회귀 통과
- 본 피처 머지 후 `docs/qa/test-cases/cuj-partner.md` 에 "이벤트 수정/취소" CUJ 추가 (별도 작업)
- runtime-qa 워커가 실물 디바이스에서 검증할 시나리오는 `docs/qa/test-cases/app-partner-smoke.md` 의 EventDetailPage 항목에 수정/취소 진입점 추가 (별도 작업)
