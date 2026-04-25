---
source_url: https://github.com/Mark-Yun/minglit/issues/434
captured_at: 2026-03-26
issue_number: 434
state: closed
labels: [P3-low, audit-report]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-03-26"
---

# 🧪 QA 일일 리포트 — 2026-03-26

> Issue #434 · closed · created 2026-03-26T02:04:49Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/434

## Body

## 🧪 QA 일일 리포트 — 2026-03-26

### 오늘 머지된 PR 테스트 현황

| PR | 제목 | 코드 변경 | 테스트 추가 | 상태 |
|----|------|----------|-----------|------|
| #431 | fix(explore): closingSoon 피드 정렬/필터링 | ✅ 로직 변경 | ✅ `explore_filter_integration_test.dart` | OK |
| #429 | fix(ci): refresh dev-seed | CI만 | - | OK (테스트 불필요) |
| #427 | fix(event): 환불 정책 UI 색상 개선 | ✅ UI 변경 | ❌ | ⚠️ 보강 필요 |
| #426 | fix(event): 환불 정책 UI cutoff → grace period | ✅ 대규모 리팩터 | ❌ | ⚠️ 보강 필요 |
| #425 | fix(home): 대시보드 카드 잘림 수정 | ✅ UI 변경 (3파일) | ❌ | ⚠️ 보강 필요 |
| #421 | fix(ci): version-bump PR number | CI + CLAUDE.md만 | - | OK (테스트 불필요) |
| #420 | fix(location): 거리 필터 프리즈 수정 | ✅ 로직 변경 | ✅ `location_service_test.dart` | ⚠️ 부분적 |
| #418 | test(golden): golden tests 추가 | 테스트 자체 | ✅ | OK |
| #417 | feat(dev): design catalog page | ✅ 새 기능 | ❌ | ⚠️ 보강 필요 |
| #416 | docs: 디자인 시스템 가이드 | docs만 | - | OK (테스트 불필요) |
| #415 | docs: IA + 메뉴 구조도 | docs만 | - | OK (테스트 불필요) |
| #414 | feat: audit-uiux 워커 추가 | scripts만 | - | OK (테스트 불필요) |
| #413 | fix(arch): doc-code mismatch 수정 | ✅ 로직 변경 | ❌ | ⚠️ 보강 필요 |

### 테스트 보강 제안

#### 1. [P2] PR #426, #427 — 환불 정책 UI (event_refund_policy_section.dart)

**변경:** `apps/app_user/lib/src/features/event/detail/event_refund_policy_section.dart` (총 +108 -69)
**기존 테스트:** ❌ 없음

**보강 제안:**
- Widget test: `apps/app_user/test/src/features/event/detail/event_refund_policy_section_test.dart`
  - cutoff 이전 → "환불 가능" 표시 + primary 컬러, D-day 텍스트 검증
  - cutoff 경과 → "환불 가능 기간이 지났습니다" + error 컬러 표시 검증
  - cutoff 당일(경계값) → `isRefundable = true` (Fix #138 경계값 포함) 검증
  - policy null → 기본값 (grace_period_hours=2, cutoff_days=7) 적용 검증
  - 인포 버튼 탭 → 상세 바텀시트 표시 검증
- 이유: 환불 정책은 결제와 연관된 핵심 UX. 경계값 로직이 복잡하고 이미 2회 수정됨 (Fix #138, #190)
- 우선순위: **P2** (금전 관련 UI이나, 결제 로직 자체는 아님)

#### 2. [P2] PR #413 — StaffGuardWrapper (staff_guard_wrapper.dart)

**변경:** `shared/packages/minglit_kit/lib/src/features/auth/ui/staff_guard_wrapper.dart` (+4 -2)
**기존 테스트:** ❌ 없음

**보강 제안:**
- Widget test: `shared/packages/minglit_kit/test/features/auth/ui/staff_guard_wrapper_test.dart`
  - 웹 환경 + 미인증 → StaffGateScreen 표시
  - 웹 환경 + @minglit.com 인증 → child 위젯 표시
  - 모바일 환경 → guard 스킵, child 바로 표시
  - localhost → guard 스킵
  - 인증 상태 변경 (onAuthStateChange) → staffGuardProvider 업데이트 검증
- 이유: 인증/보안 wrapper — 미테스트 상태에서 수정되었으며, 프로덕션 웹 접근 제어 담당
- 우선순위: **P2** (보안 관련이나 변경 범위 소규모)

#### 3. [P3] PR #425 — 파트너 대시보드 카드 (partner_home_page.dart)

**변경:** `apps/app_partner/lib/src/features/home/partner_home_page.dart` (+42 -18), `active_party_summary_scroll.dart` (+22 -8), `upcoming_events_card.dart` (+48 -8)
**기존 테스트:** `active_party_summary_scroll_test.dart` ✅, `upcoming_events_card_test.dart` ✅, `partner_home_page` ❌

**보강 제안:**
- Widget test: `apps/app_partner/test/src/features/home/partner_home_page_test.dart`
  - 대시보드 로딩 → MinglitAsyncValueWidget 로딩 상태 표시
  - 대시보드 데이터 → 5개 카드 섹션(PendingApplicants, Upcoming, ActiveParty, ClosingSoon, LocationGuide) 렌더링
  - 파티 없음 + FAB 탭 → "먼저 파티를 생성해주세요" 스낵바
  - 알림 뱃지 카운트 표시 (0이면 숨김, >99이면 "99+")
- 이유: 파트너앱 진입점 화면이나 테스트 없음. app_partner 커버리지 28.8%로 심각하게 부족
- 우선순위: **P3** (UI 레이아웃 중심)

#### 4. [P3] PR #420 — ExploreFilterChipBar (explore_filter_chip_bar.dart, 부분 커버)

**변경:** `apps/app_user/lib/src/widgets/explore_filter_chip_bar.dart` (+19 -9)
**기존 테스트:** ❌ 없음 (location_service_test만 추가됨, 이 위젯은 미커버)

**보강 제안:**
- Widget test: `apps/app_user/test/src/widgets/explore_filter_chip_bar_test.dart`
  - 초기 렌더링 → 5개 필터 칩 표시 (추천순, 마감임박, 가까운날짜, 가까운 거리, 참여 가능)
  - 정렬 칩 탭 → sortType 변경 (single selection)
  - "가까운 거리" 탭 → userLocationProvider invalidate + 위치 권한 요청
  - 위치 null 반환 → "위치 권한이 필요합니다" 스낵바
- 이유: Fix #154 수정이 포함되었고, 위치 기반 필터링은 UX 핵심 흐름
- 우선순위: **P3**

#### 5. [P3] PR #417 — DesignCatalogPage (dev 전용)

**변경:** `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart` (+792), `apps/app_user/lib/src/features/home/my_page.dart` (+26), `apps/app_partner/lib/src/features/more/more_page.dart` (+25)
**기존 테스트:** ❌ 없음

**보강 제안:**
- Smoke test: `shared/packages/minglit_kit/test/features/dev/design_catalog_page_test.dart`
  - 페이지 렌더링 크래시 없이 완료되는지 검증
- 이유: dev 전용이라 우선순위 낮지만, 792줄 신규 위젯으로 크래시 가능성 있음
- 우선순위: **P3**

### 테스트 커버리지 현황

| 프로젝트 | lib 파일 | test 파일 | 비율 |
|----------|---------|----------|------|
| app_user | 64 | 45 | 70.3% |
| app_partner | 146 | 42 | 28.8% |
| minglit_kit | 149 | 60 | 40.3% |
| Edge Functions | 39 | 53 | 135.9% |

### 테스트 없는 핵심 파일 (오늘 변경된 것 중)

| 파일 | 유형 | 심각도 |
|------|------|--------|
| `event_refund_policy_section.dart` | Widget (환불 UI) | P2 |
| `staff_guard_wrapper.dart` | Widget (인증 guard) | P2 |
| `partner_home_page.dart` | Widget (대시보드) | P3 |
| `explore_filter_chip_bar.dart` | Widget (필터 UI) | P3 |
| `design_catalog_page.dart` | Widget (dev 카탈로그) | P3 |

### 버그 이슈 회고

최근 24시간 내 생성/업데이트된 bug 이슈 없음.

### CI 상태 (최근 24h)

- 총 실행: 15회
- 성공: 8회
- 실패: 3회
  - `env-manifest` PR: lint-landing-user, lint-landing-partner, test-edge-functions 실패 (진행중 PR — flaky test 아님)
- 취소: 3회 (superseded)
- 진행중: 1회

flaky test 패턴 없음.

---

🤖 자동 생성 — audit-qa 워커 | 보강 제안 5건 (P2: 2건, P3: 3건)

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-03-26

🤖 AI Worker 분석: P2 테스트 보강 2건(환불 정책 UI, StaffGuardWrapper)과 P3 3건을 확인했습니다. P2 항목부터 테스트 작성을 시작합니다.

### Comment 2 — @Mark-Yun on 2026-03-27

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 2건 → 이슈 #486, #487 생성
  - #486: 환불 정책 UI 위젯 테스트 (P2) — 경계값 로직 복잡, 4회 수정 이력, 테스트 0
  - #487: StaffGuardWrapper 위젯 테스트 (P2) — 보안 guard, 인증 로직, 테스트 0
- skip 항목: 3건
  - PR #425 파트너 대시보드 카드 — P3 UI 레이아웃, 크래시 위험 없음
  - PR #420 ExploreFilterChipBar — P3 UI 위젯, 기능 영향 낮음
  - PR #417 DesignCatalogPage — dev 전용, 프로덕션 영향 없음

원본 리포트를 닫습니다.
