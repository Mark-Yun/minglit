---
source_url: https://github.com/Mark-Yun/minglit/issues/688
captured_at: 2026-03-28
issue_number: 688
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-03-29"
---

# 🧪 QA 일일 리포트 — 2026-03-29

> Issue #688 · closed · created 2026-03-28T16:49:11Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/688

## Body

## 🧪 QA 일일 리포트 — 2026-03-29

### 오늘 머지된 PR 테스트 현황

> 최근 24시간 기준 41개 PR 머지. 주요 PR만 발췌.

| PR | 제목 | 코드 변경 | 테스트 추가 | 상태 |
|----|------|----------|-----------|------|
| #684 | docs: architecture 감사 + design-pattern-catalog 기술 설계 | 문서만 | - | OK |
| #677 | docs: architecture 문서 최신화 | 문서만 | - | OK |
| #676 | fix: SESSION_TIMEOUT unbound variable + needs-dev gate | ✅ 스크립트 6개 | ❌ | ⚠️ 쉘 스크립트 (테스트 프레임워크 대상 외) |
| #645 | fix: PGMQ 시스템 테이블 RLS 정책 누락 | ✅ migration | ✅ pgTAP | OK |
| #644 | fix: settlement EF 권한 수준 불일치 | ✅ EF 2개 | ✅ Deno test | OK |
| #643 | fix: event-matching 인가 우회 차단 | ✅ EF 1개 | ✅ Deno test | OK |
| #617 | feat: 레이아웃 시스템 위젯 추가 | ✅ 위젯 3개 | ❌ | **보강 필요** |
| #589 | fix: purchase_history_card 날짜 | ✅ UI | ✅ widget test | OK |
| #583 | fix: error logging to silent catch blocks | ✅ 2파일 | ❌ | **보강 필요** |
| #582 | refactor: cross-feature imports | ✅ 5파일 | ❌ | **보강 필요** |
| #581 | refactor: Alchemist golden test CI | 테스트 인프라 | ✅ | OK |
| #575 | fix: shimmer loading 빈 화면 | 테스트 코드 | ✅ | OK |
| #571 | refactor: ticket selection to EventCoordinator | ✅ coordinator | ✅ coordinator test | OK |
| #570 | refactor: 디자인 시스템 토큰 값 개선 | ✅ theme/token | △ golden PNG만 | OK (시각적 회귀만) |
| #548 | feat: 신청관리 탭 (이벤트별 그루핑 + 승인/거절) | ✅ 새 페이지 | ❌ | **보강 필요** |

### 테스트 보강 제안

#### 1. [P1] PR #548 — feat: 신청관리 탭 (이벤트별 그루핑 + 인라인 승인/거절)
**변경:** `apps/app_partner/lib/src/features/application/event_application_manage_page.dart`
**제안:**
- `apps/app_partner/test/src/features/application/ui/event_application_manage_page_test.dart` 신규 작성
- 케이스 1: 이벤트별 그루핑 — 신청 목록이 이벤트 ID 기준으로 그루핑되는지
- 케이스 2: 인라인 승인 — 승인 버튼 탭 → 상태 변경 검증
- 케이스 3: 인라인 거절 — 거절 버튼 탭 → 상태 변경 검증
- 케이스 4: 빈 상태 — 신청이 없을 때 empty state 표시
- 이유: 승인/거절은 비즈니스 핵심 기능. 파트너 앱 application 영역 커버리지 0%
- 우선순위: **P1**

#### 2. [P1] PR #617 — feat: 레이아웃 시스템 위젯 (MinglitSection, MinglitContentCard, MinglitKeyValueRow)
**변경:** `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_content_card.dart`, `minglit_key_value_row.dart`, `minglit_section.dart`
**제안:**
- `shared/packages/minglit_kit/test/src/ui/widgets/common/minglit_content_card_test.dart`
- `shared/packages/minglit_kit/test/src/ui/widgets/common/minglit_key_value_row_test.dart`
- `shared/packages/minglit_kit/test/src/ui/widgets/common/minglit_section_test.dart`
- 케이스: 기본 렌더링, children 전달, 빈 content 처리, 다크모드 대응
- 이유: 공유 패키지(`minglit_kit`)의 public 위젯. 양 앱에서 사용될 재사용 컴포넌트
- 우선순위: **P1**

#### 3. [P2] PR #582 — refactor: cross-feature imports 정리
**변경:** `party_create_coordinator.dart`, `party_list_page.dart`, `entry_group_editor_screen.dart`, `qr_scanner_screen.dart`, `create_verification_controller.dart`
**제안:**
- 기존 테스트가 있다면 import 변경 후에도 통과하는지 확인
- `party_create_coordinator_test.dart` — coordinator 네비게이션 동작 회귀 검증
- 이유: cross-feature import 정리로 5파일 변경. import 경로 오류 시 런타임 크래시 가능
- 우선순위: **P2**

#### 4. [P2] PR #583 — fix: error logging to silent catch blocks
**변경:** `address_search_dialog.dart`, `feed_state_provider.dart`
**제안:**
- `apps/app_partner/test/src/features/onboarding/widgets/address_search_dialog_test.dart`
  - 케이스: API 예외 시 logger 호출 검증
- `apps/app_user/test/src/logic/feed_state_provider_test.dart`
  - 케이스: 에러 발생 시 로깅 후 graceful 처리 검증
- 이유: catch 블록의 silent failure 방지가 목적인 PR. 로깅이 실제로 동작하는지 검증 필요
- 우선순위: **P2**

### 테스트 커버리지 현황

| 프로젝트 | lib 파일 | test 파일 | 비율 |
|----------|---------|----------|------|
| app_user | 64 | 49 | 77% |
| app_partner | 152 | 49 | 32% |
| minglit_kit | 155 | 63 | 41% |
| Edge Functions | 41 | 55 | 134% |

> app_partner 커버리지(32%)가 여전히 심각하게 낮음. 특히 application/party/settlement 영역.

### 버그 이슈 회고

| 이슈 | 수정 PR | regression test | 상태 |
|------|--------|-----------------|------|
| #594 | #645 | ✅ pgTAP RLS 테스트 | OK |
| #593 | #644 | ✅ Deno EF 테스트 | OK |
| #592 | #643 | ✅ Deno EF 테스트 | OK |
| #573 | #575 | ✅ Golden 테스트 | OK |
| #544 | #583 | ❌ 없음 | **보강 필요** |
| #673 | #676 | ❌ 쉘 스크립트 | 테스트 프레임워크 대상 외 |

**열린 버그:**
- #674 — issue-worker PR 케어 이슈번호 없는 브랜치 스킵 (P2, `needs-dev`)
- #654 — 파트너 홈 요약 카드 다크모드 미적응 (P2, `needs-dev`)

### CI 상태 (최근 24h)

- 총 실행: 10회
- 성공: 7회
- 취소: 3회 (superseded by newer runs)
- 실패: **0회** ✅

### 피처 테스트 계획 (별도 처리)

- **#685** (needs-qa): design-pattern-catalog test-plan.md → **PR #687로 처리 완료**
  - 22건 테스트 케이스 (P1:10, P2:8, P3:4)

🤖 자동 생성 — issue-worker가 테스트 보강 제안을 구현 예정

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 3건 → 이슈 생성
  - #689 — test: 신청관리 탭 widget test (P1, needs-dev)
  - #690 — test: 레이아웃 시스템 위젯 테스트 (P1, needs-dev)
  - #691 — test: error logging 동작 검증 (P2, needs-dev)
- skip 항목: 1건
  - PR #582 cross-feature imports — CI(flutter analyze) 통과 완료, import 오류면 빌드에서 잡힘

**기타 참고:**
- CI 상태: 최근 24h 실패 0회 ✅
- 열린 버그 #674, #654: 이미 `needs-dev` 라벨 부여됨
- 테스트 커버리지: app_partner 32%가 가장 취약 (신규 이슈 #689가 이 영역)

원본 리포트를 닫습니다.
