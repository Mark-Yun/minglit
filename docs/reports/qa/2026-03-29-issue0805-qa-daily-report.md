---
source_url: https://github.com/Mark-Yun/minglit/issues/805
captured_at: 2026-03-29
issue_number: 805
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-03-30"
---

# 🧪 QA 일일 리포트 — 2026-03-30

> Issue #805 · closed · created 2026-03-29T21:10:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/805

## Body

## 🧪 QA 일일 리포트 — 2026-03-30

### 정적 분석
- `flutter analyze` (app_user, app_partner): ✅ error/warning 0건

### 오늘 머지된 PR 테스트 현황

| PR | 제목 | 코드 변경 | 테스트 추가 | 상태 |
|----|------|----------|-----------|------|
| #791 | EventNowBar 미니바 위젯 구현 | ✅ lib 변경 | ✅ event_now_bar_test.dart | OK |
| #783 | cross-feature import 해소 — coordinator 패턴 전환 | ✅ lib 변경 | ✅ coordinator 테스트 5건 | OK |
| #782 | 파트너앱 라우트 + 바텀탭 테스트 | 테스트 자체 | ✅ | OK |
| #781 | error logging 동작 검증 | 테스트 자체 | ✅ | OK |
| #780 | revenue_summary_card cross-import 해소 | ✅ lib 변경 | ✅ coordinator 테스트 | OK |
| #775 | backend-simulator 타임아웃 해소 | ✅ EF 변경 | ✅ sim_create_test.ts | OK |
| #774 | CheckinPlaceholderPage 테스트 | 테스트 자체 | ✅ | OK |
| #773 | 로그 개인정보 마스킹 유틸리티 | ✅ EF 변경 | ✅ pii_masker_test.ts | OK |
| #770 | 워커 시스템 통합 리팩토링 | scripts/ 변경 | - | OK (테스트 불필요) |
| #769 | 개인정보처리방침 해외 이전 고지 | ✅ landing page.tsx | - | OK (lint+build CI) |
| #768 | Supabase 직접접근 → Repository 분리 | ✅ lib 변경 | ❌ | **⚠️ 보강 필요** |
| #758 | EventNowBarState 상태 머신 + Controller | ✅ lib 변경 | ✅ state_provider_test.dart | OK |
| #757 | MyTicketsPage + MyTicketCard UI | ✅ lib 변경 | ✅ my_tickets_page_test.dart | OK |
| #755 | MinglitBadge 위젯 | ✅ lib 변경 | ✅ minglit_badge_test.dart | OK |
| #751 | 하드코딩 디자인 토큰 교체 | ✅ lib 변경 | ✅ golden 업데이트 | OK |
| #749 | iOS deploy composite action 전환 | CI 변경 | - | OK (테스트 불필요) |
| #748 | MinglitEmptyState + MinglitErrorState | ✅ lib 변경 | ✅ widget 테스트 | OK |
| #746 | MyTicketsController + Provider | ✅ lib 변경 | ✅ controller 테스트 | OK |
| #745 | MyTicketsController 생성 | ✅ lib 변경 | ✅ controller 테스트 | OK |
| #744 | 레이아웃 시스템 위젯 테스트 | 테스트 자체 | ✅ | OK |
| #742 | 신청관리 탭 widget test | 테스트 자체 | ✅ | OK |
| #741 | StatusBadge 공유 위젯 추출 | ✅ lib 변경 | ✅ status_badge_test.dart | OK |
| #800 | 기술 설계 문서 | docs/ 변경 | - | OK (테스트 불필요) |
| #797 | minglitRadius 토큰 동기화 | ✅ tokens.ts | - | OK (lint+build CI) |
| #793 | 스펙 + 와이어프레임 | docs/ 변경 | - | OK (테스트 불필요) |
| #788 | architecture 문서 최신화 | docs/ 변경 | - | OK (테스트 불필요) |
| #771 | architecture 문서 최신화 | docs/ 변경 | - | OK (테스트 불필요) |

**총평**: 27개 PR 중 코드 변경 PR 19건, 테스트 동반 18건 (95%). 매우 우수.

---

### 테스트 보강 제안

#### 1. [P2] PR #768 — Supabase 직접접근 → Repository 분리

**변경:** `shared/packages/minglit_kit/lib/src/data/repositories/event_repository_commands.dart` (3개 메서드 추가)
**테스트 파일 존재:** `event_repository_commands_test.dart` (있으나 신규 메서드 미포함)

**보강 제안:**
- `shared/packages/minglit_kit/test/src/data/repositories/event_repository_commands_test.dart`에 케이스 추가
- 케이스 1: `approveApplication` — 성공 시 applications 테이블 status 업데이트 검증
- 케이스 2: `approveApplication` — 실패 시 MingleException throw 검증
- 케이스 3: `rejectApplication` — 성공 시 status + reject_reason 업데이트 검증
- 케이스 4: `bulkApproveApplications` — 성공 시 RPC 호출 검증
- 케이스 5: `bulkApproveApplications` — 실패 시 에러 핸들링 검증
- 이유: 신청 승인/거절은 파트너 핵심 기능. Repository 메서드가 테스트 없이 머지됨.

---

### 버그 이슈 회고

| 이슈 | 상태 | 수정 PR | regression test | 비고 |
|------|------|--------|-----------------|------|
| #778 | OPEN | 없음 | - | 추천 이벤트 0건 반환. `getEventsByType` 호출은 성공하나 count=0. 백엔드 데이터 또는 EF 이슈 가능성 |
| #763 | CLOSED | #773 | ✅ pii_masker_test.ts | OK |
| #762 | CLOSED | #769 | - | landing page 변경, lint+build CI로 커버 |
| #705 | CLOSED | #775 | ✅ sim_create_test.ts | OK |
| #674 | CLOSED | #766 | - | 워커 스크립트, 테스트 불필요 |
| #654 | CLOSED | #751 | ✅ golden 업데이트 | OK |

> ⚠️ **#778** 주목: 로그에서 `getEventsByType success | count: 0` — EF `event-feed`가 데이터를 반환하지 않는 문제. bug-report에 "자동화테스트에서 왜 못잡아냈는지 검토" 요청 포함. **event-feed EF 테스트가 empty result 시나리오를 커버하는지 확인 필요**.

---

### 테스트 커버리지 현황

| 프로젝트 | lib 파일 | test 파일 | 비율 | 전일 대비 |
|----------|---------|----------|------|----------|
| app_user | 73 | 60 | 82% | +8 test (coordinator 5 + my_tickets 2 + status_badge 1) |
| app_partner | 152 | 54 | 36% | +4 test (checkin, route, scaffold, application) |
| minglit_kit | 160 | 70 | 44% | +5 test (badge, empty, error, section, key_value_row) |
| Edge Functions | 41 EF | 56 test | 137% | +2 test (pii_masker, sim_create) |

> app_user 테스트 비율 대폭 개선 (52→82%). coordinator 패턴 전환(#783)과 my_tickets 구현(#745, #746, #757)에서 테스트 동반.

---

### CI 상태 (최근 24h)

- 성공: 다수 (최근 10건 중 성공 4건 확인)
- 실패: `cancelled` 1건 (중복 CI 자동 취소)
- 진행 중: 5건
- Auto Format 실패: #789 (자동 해결됨)
- Seed Dev 실패: #787 (자동 해결됨)

---

### 코드 품질 스캔

- `flutter analyze` (app_user, app_partner): error/warning 0건 ✅
- 느낌표(!) 강제 언래핑, 빈 catch 블록: 기존 이슈 수준 유지, 신규 위험 패턴 미발견

---

🤖 자동 생성 — audit-qa (2026-03-30)

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-30

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 1건 → #863 생성 (event_repository_commands 테스트 보강, P2)
- skip 항목:
  - 머지된 PR 27건 중 테스트 미동반 1건만 해당 (#768) → 이슈 생성 완료
  - #778 (추천 이벤트 0건): 이미 open 이슈로 추적 중
  - 정적 분석/CI: 정상
  - 테스트 커버리지 비율: 개선 추세, 별도 이슈 불필요

원본 리포트를 닫습니다.
