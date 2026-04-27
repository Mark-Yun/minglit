---
source_url: https://github.com/Mark-Yun/minglit/issues/722
captured_at: 2026-03-29
issue_number: 722
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-29"
---

# 🎨 UI/UX 감사 — 2026-03-29

> Issue #722 · closed · created 2026-03-29T02:16:07Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/722

## Body

## UI/UX 디자인 감사 리포트 — 2026-03-29

### 1. 디자인 토큰 준수 감사

#### A. 하드코딩 색상 (13건)

| 파일 | 라인 | 값 | 문제 |
|------|------|----|------|
| `todo_summary_chips.dart` | 28,38,48,95,105,113,121 | `Color(0xFFFFF0F0)`, `Color(0xFFF0F0FF)`, `Color(0xFFFFF8E1)`, `Color(0xFFF5F5F5)`, `Color(0xFFAAAAAA)` (×3) | 다크모드 미대응. `MinglitColors`/`colorScheme` 시맨틱 컬러로 교체 필요 |
| `settlement_shimmer.dart` | 60-64 | `Color(0xFF3A3A3A)`, `Color(0xFFE0E0E0)`, `Color(0xFF4A4A4A)`, `Color(0xFFF5F5F5)` | shimmer 색상 → `colorScheme.surface`/`surfaceVariant` 기반 교체 |
| `checkin_placeholder_page.dart` | 98 | `Color(0xFF6C3CE1)` | seedColor → `MinglitColors.primary` 사용 |

#### B. 하드코딩 폰트 크기 (6건)

| 파일 | 라인 | 값 |
|------|------|----|
| `onboarding_step_guide.dart` | 35, 401, 413 | `fontSize: 40`, `fontSize: 24`, `fontSize: 10` |
| `event_action_card.dart` | 218 | `fontSize: 28` |
| `ticket_list_item.dart` | 169 | `fontSize: 11` |
| `settlement_status_badge.dart` | 89 | `fontSize: compact ? 11 : 13` |

#### C. 문서-코드 불일치 (수정 완료 → PR #720)

| 항목 | 문서 | 코드 | 조치 |
|------|------|------|------|
| 파트너 BottomNav | 4탭 | **5탭** (홈/신청관리/체크인/정산/더보기) | ✅ 문서 수정 |
| 파티 라우트 | `/parties` | `/more/parties` | ✅ 문서 수정 |
| `selectableCardSubtitle` 기반 | `bodySmall` | `labelSmall` | ✅ 문서 수정 |
| BottomSheet radius | 24px | `MinglitRadius.card` = **16px** | ✅ 문서 수정 |
| 유저 앱 네비게이션 | BottomNav 2탭 | **Shell 없음** (독립 top-level) | ✅ 문서 수정 |
| 누락 라우트 6건 | 미기재 | `/welcome`, `/applications`, `/checkin`, `/settlement/bank-account`, `/settlement/:id`, `/more/notification-settings` | ✅ 문서 수정 |
| 유저 앱 누락 라우트 3건 | 미기재 | `/partners/:id/events`, `/my/privacy`, `/my/blocked-partners` | ✅ 문서 수정 |

#### D. 미문서화 컴포넌트

| 항목 | 설명 |
|------|------|
| `MinglitBottomCTA` | 코드에 존재하나 `02-components.md`에 미등재 |
| `MinglitTextThemeExtension` | 이미 사용 중이나 디자인 시스템 문서에 미등재 |
| light-mode `divider` 색상 | `#E5E7EB` 직접 사용, `MinglitColors.divider` 토큰 없음 (dark만 있음) |

### 2. Golden Test 커버리지

| 항목 | 수 |
|------|---|
| 전체 Page/Screen 파일 | 49 |
| Golden Test 파일 | 9 |
| 테스트된 페이지 | 5 (10.2%) |
| **미커버 페이지** | **44 (89.8%)** |

### 3. 골든 이미지 시각 분석

**event_card_full (라이트/다크)**:
- ✅ 브랜드 퍼플(#9900FF) 정원 표시에 사용
- ⚠️ 다크모드에서 카드와 배경 경계 구분 약함 — border 또는 명도 차이 필요

**settlement_empty_state (라이트/다크)**:
- ✅ 빈 상태 중앙 정렬 일관성 양호
- ✅ 다크모드 전환 자연스러움
- ⚠️ CTA 버튼 없는 빈 상태 — 다른 빈 상태(settlement subtitle 변형)와 비교 시 CTA 색상 통일 필요

### 4. 접근성

| 토큰 | 현재 값 | 대비율 | AA 기준 |
|------|---------|--------|---------|
| `MinglitColors.success` | `#22C55E` | ~2.8:1 | ❌ 미달 (4.5:1 필요) |
| `MinglitColors.warning` | `#F59E0B` | ~2.1:1 | ❌ 미달 (4.5:1 필요) |

### 5. needs-uiux 이슈 상태

- **#651** (배경색 계층구조 + screenEdge 축소): 디자인 토큰 레벨 변경 — 직접 수정 가능 영역
- **#652** (UI/UX 개선 제안): 하드코딩 칩 색상, 빈 상태 CTA, 접근성 — 직접 수정 가능 영역

두 이슈 모두 이전 감사(#649)에서 생성된 개선 이슈로, 코드 수정 PR이 필요한 상태.

### 6. 문서 최신화 PR

- **#720**: `menu-structure.md`, `information-architecture.md`, `03-patterns.md`, `04-navigation.md` 최신화 (auto-merge 활성화)

### 우선순위 요약

| 순위 | 항목 | 유형 |
|------|------|------|
| P1 | 하드코딩 칩 색상 7건 (todo_summary_chips) — 다크모드 결함 | 직접 수정 가능 |
| P1 | #651 배경색 계층구조 + screenEdge 축소 | 직접 수정 가능 |
| P2 | shimmer 하드코딩 색상 4건 | 직접 수정 가능 |
| P2 | 접근성 색상 대비율 (success/warning) | 직접 수정 가능 |
| P2 | `MinglitBottomCTA`, `MinglitTextThemeExtension` 문서화 | 직접 수정 가능 |
| P3 | 하드코딩 fontSize 6건 | 직접 수정 가능 |
| P3 | golden test 커버리지 확대 (89.8% 미커버) | 점진적 확대 |

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 0건 (신규 이슈 생성 불필요)
- skip 항목: 전체 — 모든 항목이 기존 이슈에서 이미 추적 중

**기존 이슈 매핑:**

| 리포트 항목 | 기존 이슈 | 상태 |
|---|---|---|
| 하드코딩 색상 13건 (1A) | #596 (refactor, P3), #654 (dark mode fix, P2) | OPEN, needs-dev |
| 하드코딩 폰트 크기 6건 (1B) | #596 | OPEN, needs-dev |
| 문서-코드 불일치 (1C) | PR #720 | ✅ 수정 완료 |
| 미문서화 컴포넌트 (1D) | Skip — P3 문서, 출시 전 배제 | - |
| 골든 테스트 커버리지 (2) | #574 | OPEN, needs-dev |
| 골든 이미지 시각 분석 (3) | #652 (다크모드 카드 경계) | OPEN |
| 접근성 대비율 (4) | #652 (success/warning 색상) | OPEN |
| needs-uiux #651, #652 (5) | 이미 OPEN | OPEN |

원본 리포트를 닫습니다.
