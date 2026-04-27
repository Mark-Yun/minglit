---
source_url: https://github.com/Mark-Yun/minglit/issues/547
captured_at: 2026-03-27
issue_number: 547
state: closed
labels: [P2-medium, audit-report]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-03-28"
---

# 🧪 QA 일일 리포트 — 2026-03-28

> Issue #547 · closed · created 2026-03-27T23:12:57Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/547

## Body

## 🧪 QA 일일 리포트 — 2026-03-28

### 오늘 머지된 PR 테스트 현황 (24h 기준: 27개 PR)

| PR | 제목 | 유형 | 테스트 | 상태 |
|----|------|------|--------|------|
| #538 | 환불 정책 UI 위젯 테스트 추가 | 테스트 | ✅ | OK |
| #537 | 디자인 카탈로그 5개 탭 추가 | lib 변경 | ❌ | P3 |
| #535 | architecture 문서 최신화 | docs | - | OK |
| #534 | backend-simulator parallelize run phase | bug fix + test | ✅ | OK |
| #533 | 신청 승인/거절 Edge Functions | feature + test | ✅ | OK |
| #532 | 체크인 탭 이벤트 자동 선택 + QR 스캐너 | feature | ❌ | ⚠️ P1 |
| #530 | 파트너 홈 대시보드 리디자인 | feature | ❌ | ⚠️ P2 |
| #529 | 정산 탭 매출 요약 카드 그라디언트 | UI 변경 | ❌ | P3 |
| #528 | Edge Functions deno.json 추가 | config | - | OK |
| #527 | 파트너 전용 테마 컬러 적용 | feature + test | ✅ | OK |
| #526 | 파트너앱 바텀탭 5개 구조로 변경 | refactor | ❌ | ⚠️ P2 |
| #515 | partner dashboard wireframe and spec | docs | - | OK |
| #514 | EventCard golden tests | 테스트 | ✅ | OK |
| #512 | config.toml Edge Function 섹션 추가 | config | - | OK |
| #511 | sim_refund parallelize | bug fix | ❌ | P3 |
| #508 | simulator query LIMIT | bug fix | ❌ | P3 |
| #506 | supabase-deploy cancel-in-progress 비활성화 | CI | - | OK |
| #505 | 다크모드 골든테스트 variant 추가 | 테스트 | ✅ | OK |
| #504 | 서버 공개키로 티켓 검증 | bug fix + test | ✅ | OK |
| #503 | supabase-deploy 통합 | CI | - | OK |
| #502 | cancel-in-progress 비활성화 | CI | - | OK |
| #501 | 누락 디자인 토큰 추가 | 토큰 상수 | ❌ | P3 |
| #500 | MinglitOpacity 토큰 클래스 추가 | 토큰 + lib | ❌ | P3 |
| #499 | 디자인 토큰 문서 보강 | docs | - | OK |
| #498 | .list() → listV2 전환 | dev-seed | ❌ | P3 |
| #497 | party ↔ ticket 양방향 커플링 해소 | refactor | ❌ | ⚠️ P2 |
| #495 | 하드코딩 spacing → 토큰 마이그레이션 | refactor | ❌ | P3 |
| #494 | dev-seed static-only mode | refactor + test | ✅ | OK |
| #493 | daily-e2e → simulation pipeline | CI + migration | - | OK |
| #491 | UX 라이팅 가이드 개편 | docs | - | OK |

---

### 테스트 보강 제안

#### 1. [P1] PR #532 — 체크인 탭 이벤트 자동 선택 + QR 스캐너
**변경 파일:**
- `apps/app_partner/lib/src/features/checkin/checkin_placeholder_page.dart` (+242)
- `apps/app_partner/lib/src/features/checkin/qr_scanner_screen.dart` (+20/-6)
- `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` (+16/-3)

**보강 제안:**
- `apps/app_partner/test/src/features/checkin/checkin_placeholder_page_test.dart` 신규 작성
  - 이벤트가 1개일 때 자동 선택되는지 검증
  - 이벤트가 여러 개일 때 선택 UI 표시 검증
  - 이벤트가 없을 때 빈 상태 표시 검증
- `apps/app_partner/test/src/features/checkin/qr_scanner_screen_test.dart` 보강
  - 스캔 성공 시 체크인 처리 flow 검증
- **이유:** 체크인은 현장 운영 핵심 기능. 이벤트 자동 선택 로직 오류 시 잘못된 이벤트에 체크인될 위험
- **우선순위:** P1

#### 2. [P2] PR #530 — 파트너 홈 대시보드 리디자인
**변경 파일:**
- `apps/app_partner/lib/src/features/home/partner_home_page.dart` (+279/-114)
- `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` (신규 +513)
- `apps/app_partner/lib/src/features/home/widgets/onboarding_step_guide.dart` (신규 +437)
- `apps/app_partner/lib/src/features/home/widgets/todo_summary_chips.dart` (신규 +129)
- `apps/app_partner/lib/src/features/home/widgets/weekly_stats_row.dart` (신규 +149)

**보강 제안:**
- `apps/app_partner/test/src/features/home/widgets/event_action_card_test.dart`
  - 이벤트 상태별(진행중/예정/종료) 올바른 액션 버튼 표시 검증
  - 탭 시 올바른 화면 이동 검증
- `apps/app_partner/test/src/features/home/widgets/onboarding_step_guide_test.dart`
  - 각 온보딩 단계 완료 상태 표시 검증
  - 미완료 단계 탭 시 해당 화면 이동 검증
- `apps/app_partner/test/src/features/home/widgets/todo_summary_chips_test.dart`
  - 할일 데이터에 따른 칩 렌더링 검증
- `apps/app_partner/test/src/features/home/widgets/weekly_stats_row_test.dart`
  - 통계 데이터 포맷팅 검증 (0건, 대량 데이터)
- **이유:** 파트너 홈은 첫 화면으로 1507줄 신규 코드. 위젯 단위 테스트로 리그레션 방지 필요
- **우선순위:** P2

#### 3. [P2] PR #526 — 파트너앱 바텀탭 5개 구조로 변경
**변경 파일:**
- `apps/app_partner/lib/src/features/checkin/checkin_placeholder_page.dart` (신규)
- `apps/app_partner/lib/src/routing/app_routes.dart` (+59/-36)
- `apps/app_partner/lib/src/ui/shell/partner_scaffold.dart` (+21/-10)

**보강 제안:**
- `apps/app_partner/test/src/routing/app_routes_test.dart`
  - 5개 탭 라우트 정상 생성 검증
  - 각 탭 전환 시 올바른 페이지 로드 검증
- `apps/app_partner/test/src/ui/shell/partner_scaffold_test.dart`
  - 바텀 네비게이션 5개 아이템 렌더링 검증
  - 탭 선택 시 상태 변경 검증
- **이유:** 앱 내비게이션 구조 변경은 전체 UX에 영향. 탭 누락/순서 오류 방지
- **우선순위:** P2

#### 4. [P2] PR #497 — party ↔ ticket 양방향 커플링 해소
**변경 파일:**
- `apps/app_partner/lib/src/features/ticket/logic/ticket_data_providers.dart` (신규 +35)
- `apps/app_partner/lib/src/features/ticket/create/ticket_create_page.dart` (+8/-9)
- `apps/app_partner/lib/src/features/ticket/edit/ticket_edit_page.dart` (+10/-9)

**보강 제안:**
- `apps/app_partner/test/src/features/ticket/logic/ticket_data_providers_test.dart`
  - provider가 올바른 데이터를 반환하는지 검증
  - party 없이 ticket 데이터 독립 접근 검증
- **이유:** 커플링 해소 리팩터링에서 의존성 누락 시 런타임 에러 발생 가능
- **우선순위:** P2

#### 5. [P2] 이슈 #459 — 에러 삼킴 catch 블록 로깅 추가 (수정 PR #490) regression test
**수정 파일:**
- `apps/app_partner/lib/src/features/settlement/bank_account_page.dart`
- `apps/app_user/lib/src/features/event/detail/report_bottom_sheet.dart`
- `apps/app_user/lib/src/features/ticket/ui/ticket_selection_sheet.dart`

**regression test:** ❌ 없음

**보강 제안:**
- `apps/app_partner/test/src/features/settlement/bank_account_page_test.dart`
  - API 에러 시 로그 출력 + 사용자에게 에러 표시 검증
- `apps/app_user/test/src/features/ticket/ui/ticket_selection_sheet_test.dart`
  - 티켓 조회 실패 시 에러 핸들링 검증
- **이유:** 에러 삼킴은 디버깅 난이도를 높이는 반복 패턴. regression test로 재발 방지
- **우선순위:** P2

---

### 버그 이슈 회고

| 이슈 | 상태 | 수정 PR | regression test | 비고 |
|------|------|--------|-----------------|------|
| #458 | ✅ Closed | #504 | ✅ 있음 | checkin 서버 공개키 검증 |
| #459 | ✅ Closed | #490 | ❌ 없음 | 에러 삼킴 로깅 — 위 제안 #5 참고 |
| #510 | ✅ Closed | #512 | - | config.toml 누락 (테스트 불필요) |
| #543 | 🟡 Open | 미정 | - | party_repository null 크래시 |
| #544 | 🟡 Open | 미정 | - | error swallowing 로깅 추가 |
| #542 | 🔴 Open | 미정 | - | Daily Backend Simulation 실패 |

---

### CI 상태 (최근 24h)
- 총 실행: 20회
- 성공: 16회
- 실패: 3회
  - 1회: `test-flutter-apps (app_partner)` 실패 → 후속 재실행에서 통과 (일시적)
  - 나머지: CodeRabbit 타임아웃 관련

**Flaky test 의심:** 없음 (실패가 반복되지 않음)

---

### 요약

| 항목 | 수치 |
|------|------|
| 머지된 PR | 27개 |
| 테스트 포함 PR | 8개 |
| 테스트 불필요 (docs/CI/config) | 12개 |
| ⚠️ 테스트 보강 필요 | 4개 (P1: 1, P2: 3) |
| P3 (낮은 우선순위) | 7개 |
| 열린 버그 이슈 | 3개 (#542, #543, #544) |

🤖 자동 생성 — audit-qa worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: **2건** → 이슈 #670, #671 생성 (P2-medium, needs-dev)
- skip 항목: **5건**
  - PR #530 홈 대시보드 테스트: 위젯 테스트 5개 이미 존재
  - PR #497 ticket 커플링 테스트: 35줄 trivial provider (P3 — 출시 전 배제)
  - #459 에러 삼킴 regression: #544에서 이미 수정 완료 (CLOSED)
  - Bug #542, #543, #544: 모두 CLOSED
  - P3 항목 7건: 출시 전 배제 (스타일/컨벤션/디자인카탈로그 등)

| 생성 이슈 | 제목 | 우선순위 |
|----------|------|---------|
| #670 | test: CheckinPlaceholderPage 위젯 테스트 추가 | P2-medium |
| #671 | test: 파트너앱 라우트 + 바텀탭 네비게이션 테스트 추가 | P2-medium |

원본 리포트를 닫습니다.
