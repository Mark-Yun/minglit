---
source_url: https://github.com/Mark-Yun/minglit/issues/603
captured_at: 2026-03-28
issue_number: 603
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-28"
---

# 🎨 UI/UX 감사 — 2026-03-28

> Issue #603 · closed · created 2026-03-28T07:55:20Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/603

## Body

## UI/UX 디자인 감사 리포트 — 2026-03-28

### 1. 디자인 토큰 위반 사항

#### A. 하드코딩 색상 (13건 / 4파일)

| 파일 | 라인 | 값 | 용도 |
|------|------|-----|------|
| `app_partner/.../todo_summary_chips.dart` | 28, 38, 48 | `Color(0xFFFFF0F0)`, `Color(0xFFF0F0FF)`, `Color(0xFFFFF8E1)` | 칩 배경색 — 시맨틱 토큰 필요 |
| `app_partner/.../todo_summary_chips.dart` | 95, 105, 113, 121 | `Color(0xFFF5F5F5)`, `Color(0xFFAAAAAA)` ×3 | 비활성 칩 — `MinglitColors` 확장 필요 |
| `app_partner/.../settlement_shimmer.dart` | 60-64 | `Color(0xFF3A3A3A)` 등 4건 | 시머 색상 — 테마별 토큰 필요 |
| `app_partner/.../checkin_placeholder_page.dart` | 98 | `Color(0xFF6C3CE1)` | 파트너 primary 직접 사용 → `MinglitPartnerColors.primary` 사용해야 함 |
| `shared/.../splash_screen.dart` | 41, 166 | `Color(0xFF21FFFE)`, `Color(0xFF7B2FBE)` | 스플래시 특수효과 — 허용 가능하나 토큰 등록 권장 |

**심각도**: P2 — `checkin_placeholder_page.dart`는 이미 존재하는 `MinglitPartnerColors.primary` 토큰 미사용으로 즉시 수정 가능.

#### B. 하드코딩 폰트 크기 (5건 / 3파일)

| 파일 | 라인 | 값 | 권장 |
|------|------|-----|------|
| `app_partner/.../event_action_card.dart` | 218 | `fontSize: 28` | `TextTheme.headlineSmall` 사용 |
| `app_partner/.../onboarding_step_guide.dart` | 35 | `fontSize: 40` (displayLarge copyWith) | displayLarge 그대로 사용하거나 토큰 확장 |
| `app_partner/.../onboarding_step_guide.dart` | 401, 413 | `fontSize: 24`, `fontSize: 10` | 이모지/배지 — TextTheme 적용 |
| `app_partner/.../ticket_list_item.dart` | 169 | `fontSize: 11` | `labelSmall` 또는 토큰 확장 |

**심각도**: P3 — 대부분 파트너 앱 온보딩/카드 위젯. 기능에 영향 없으나 시스템 일관성 저해.

#### C. 하드코딩 간격 (settlement 영역 집중)

| 파일 | 위반 수 | 주요 값 |
|------|---------|---------|
| `settlement_detail_page.dart` | 7건 | `16`, `4`, `6` — `MinglitSpacing.medium`, `.titleToBody`, `.xsmall2` 사용해야 함 |
| `bank_account_page.dart` | 5건 | `16` — `MinglitSpacing.medium` |
| `settlement_shimmer.dart` | 1건 | `16`, `14` |
| `download_bottom_sheet.dart` | 1건 | `24` — `MinglitSpacing.large` |
| `settlement_card.dart` | 1건 | `16`, `12` |
| `settlement_empty_state.dart` | 1건 | `32` — `MinglitSpacing.xlarge` |

**심각도**: P3 — settlement 피처 전반에 걸쳐 시맨틱 토큰 적용 누락. 값 자체는 토큰과 동일하지만 상수 참조가 아닌 매직넘버 사용.

### 2. Golden Test 커버리지

| 항목 | 수치 |
|------|------|
| 전체 Page/Screen | **51개** (39 pages + 12 screens) |
| Golden Test 보유 | **5개** (9.8%) |
| **미커버** | **46개** (90.2%) |

**커버된 화면**: home_page (양 앱), my_page, search_page, party_list_page

**우선 추가 대상** (사용자 핵심 플로우):
- `event_detail_page` (양 앱)
- `purchase_history_page` (app_user)
- `settlement_page` (app_partner)
- `login_page` (양 앱)
- `partner_apply_page` (app_partner)

### 3. 골든 이미지 시각 분석

| 이미지 | 결과 |
|--------|------|
| `event_card_full.png` | ✅ 브랜드 퍼플(#9900FF) 적용, 정보 계층(제목→날짜→인원) 명확, 카드 라운딩 일관 |
| `settlement_empty_state_default.png` | ✅ 빈 상태 패턴(아이콘+텍스트) 준수, 중앙 정렬, 적절한 여백. 다만 CTA 버튼 없음 — `03-patterns.md` Empty State 가이드에서 CTA 권장 |

### 4. 문서-코드 일치

**동기화 상태**: ✅ `docs/ux/design-system/` 7개 가이드와 `minglit_design_tokens.dart` 토큰 값 완전 일치.

**미구현 TODO** (문서에 명시):
- `EmptyState` 공용 위젯 (`03-patterns.md` §4)
- `ErrorState` 공용 위젯 (`03-patterns.md` §6)
- `ListItem` 공용 위젯 (`03-patterns.md` §2)
- Pull to Refresh 표준화 (`03-patterns.md` §7)
- Standard Curve 토큰 (`01-foundation.md`)

### 5. 요약

| 카테고리 | 상태 | 위반 수 |
|----------|------|---------|
| 하드코딩 색상 | ⚠️ | 13건 |
| 하드코딩 폰트 | ⚠️ | 5건 |
| 하드코딩 간격 | ⚠️ | 16건 |
| Golden Test 커버리지 | ❌ | 9.8% (46/51 미커버) |
| 문서-코드 동기화 | ✅ | 일치 |
| 공용 위젯 TODO | 📝 | 5개 미구현 |

---
*자동 생성: audit-uiux worker*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 0건 (신규 이슈 생성 없음)
- 기존 이슈로 커버: 4건
  - 하드코딩 색상/폰트 (13+5건) → #596 (needs-dev)
  - Golden Test 커버리지 → #574 (needs-dev)
  - EmptyState/ErrorState 공용 위젯 → #619 (needs-dev)
  - ListItem 공용 위젯 → #625 (needs-dev)
- skip 항목:
  - 하드코딩 간격 16건: P3, 값 자체는 토큰과 동일. 출시 전 배제
  - Pull to Refresh 표준화: P3, 출시 전 배제
  - Standard Curve 토큰: P3, 출시 전 배제

원본 리포트를 닫습니다.
