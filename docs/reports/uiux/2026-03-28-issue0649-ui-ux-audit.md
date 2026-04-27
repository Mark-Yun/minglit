---
source_url: https://github.com/Mark-Yun/minglit/issues/649
captured_at: 2026-03-28
issue_number: 649
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-28"
---

# 🎨 UI/UX 감사 — 2026-03-28

> Issue #649 · closed · created 2026-03-28T10:15:24Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/649

## Body

## UI/UX 디자인 감사 리포트 — 2026-03-28

### 1. 디자인 토큰 위반

#### A. 하드코딩 색상 (14건)
| 파일 | 라인 | 값 |
|------|------|-----|
| `app_partner/.../todo_summary_chips.dart` | 28,38,48,95,105,113,121 | `Color(0xFFFFF0F0)`, `Color(0xFFF0F0FF)`, `Color(0xFFFFF8E1)`, `Color(0xFFF5F5F5)`, `Color(0xFFAAAAAA)` x3 |
| `app_partner/.../settlement_shimmer.dart` | 60,61,63,64 | `Color(0xFF3A3A3A)`, `Color(0xFFE0E0E0)`, `Color(0xFF4A4A4A)`, `Color(0xFFF5F5F5)` |
| `app_partner/.../checkin_placeholder_page.dart` | 98 | `Color(0xFF6C3CE1)` |
| `shared/.../splash_screen.dart` | 41,166 | `Color(0xFF21FFFE)`, `Color(0xFF7B2FBE)` |

**조치**: `MinglitColors` 또는 `Theme.of(context).colorScheme`으로 교체 필요.

#### B. 하드코딩 폰트 크기 (5건)
| 파일 | 라인 | 값 |
|------|------|-----|
| `app_partner/.../event_action_card.dart` | 218 | `fontSize: 28` |
| `app_partner/.../onboarding_step_guide.dart` | 401, 413 | `fontSize: 24`, `fontSize: 10` |
| `app_partner/.../settlement_status_badge.dart` | 89 | `fontSize: 11/13` |
| `app_partner/.../ticket_list_item.dart` | 169 | `fontSize: 11` |

**조치**: `Theme.of(context).textTheme`의 적절한 스타일로 교체 필요.

#### C. 하드코딩 간격: **0건** ✅
모든 간격이 `MinglitSpacing` 토큰을 올바르게 사용 중.

#### D. 비표준 버튼 (59건)
`ElevatedButton`, `TextButton`, `OutlinedButton` 직접 사용이 두 앱 전반에 걸쳐 59건 발견.
주요 집중 영역:
- `app_partner/features/party/` (12건)
- `app_partner/features/onboarding/` (8건)
- `app_partner/features/verification/` (6건)
- `app_user/features/payment/` (8건)
- `app_user/features/event/` (7건)

**조치**: 테마 기반 버튼 사용 확인 필요. `MinglitButton` 위젯 도입 후 마이그레이션 권장.

---

### 2. Golden Test 커버리지

| 항목 | 수치 |
|------|------|
| 전체 page/screen 파일 | **49개** |
| golden test 파일 | **9개** |
| golden 이미지 | **78개** (light/dark 포함) |
| **커버리지** | **8%** (4/49 페이지) |

커버되는 화면: `home_page`, `my_page`, `search_page` (app_user) + `home_page`, `party_list_page` (app_partner) + 위젯 단위 (event_card, settlement_empty, upcoming_events, closing_soon)

**미커버 45개 화면** 중 우선순위 높은 것:
- `event_detail_page` (양쪽 앱)
- `login_page` / `partner_login_page`
- `payment_success_screen`
- `party_create_wizard_page`
- `settlement_page`

---

### 3. 골든 이미지 시각 분석

| 심각도 | 문제 | 화면 |
|--------|------|------|
| **HIGH** | 파트너 홈 상단 요약 카드가 다크모드에서 미적응 — 라이트 배경 유지 | `partner_home_page_with_data_dark` |
| **MEDIUM** | 파티 목록 빈 상태 CTA가 브랜드 퍼플 대신 회색 사용 | `party_list_page_empty` |
| **MEDIUM** | 유저 홈에서 브랜드 퍼플 과소 사용 — 오렌지/틸이 더 지배적 | `home_page_with_events` |
| LOW | 다크모드 이벤트 카드 경계 구분 부족 | `event_card_full_dark` |
| LOW | 정산 빈 상태 부제 텍스트 너비 과다 | `settlement_empty_state_subtitle` |

---

### 4. 문서-코드 불일치 (수정 완료)

PR #588 에서 `02-components.md` 수정:
- Card `borderRadius`: 문서 `24` → 코드 `16` (MinglitRadius.card) → **16으로 수정**
- Dark Mode 소스 라인 참조 5건: 모두 `materialThemeDark` 메서드 실제 위치로 업데이트

---

### 5. 접근성 참고

`07-accessibility.md` 기준:
- `success` 색상 (#22C55E): 대비율 2.8:1 — **WCAG AA 미달** ⚠️
- `warning` 색상 (#F59E0B): 대비율 2.1:1 — **WCAG AA 미달** ⚠️
- `primary` 색상 (#9900FF on white): 대비율 ~3.9:1 — 일반 텍스트 AA 미달, 큰 텍스트는 통과

---

### 관련 PR
- #588: `docs/ux/design-system/02-components.md` 문서 수정

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 1건 → #654 생성 (파트너 홈 다크모드 미적응, P2)
- skip 항목:
  - 하드코딩 색상 나머지 7건 (settlement_shimmer, checkin_placeholder, splash_screen): P3 스타일 — 출시 전 배제
  - 하드코딩 폰트 크기 5건: P3 스타일 — 출시 전 배제
  - 비표준 버튼 59건: P3 대규모 마이그레이션 — 출시 전 배제. MinglitButton 도입 후 점진 전환 권장
  - Golden test 커버리지 8%: P2이나, 피처 완성 후 보강. 현재 이슈 생성 불필요
  - 접근성 WCAG AA 미달 (success/warning 색상): P2이나 복잡한 디자인 결정 필요 — 출시 후 대응
  - 문서-코드 불일치: PR #588에서 이미 수정 완료

원본 리포트를 닫습니다.
