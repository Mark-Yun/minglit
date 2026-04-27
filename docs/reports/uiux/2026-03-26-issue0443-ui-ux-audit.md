---
source_url: https://github.com/Mark-Yun/minglit/issues/443
captured_at: 2026-03-26
issue_number: 443
state: closed
labels: [audit-report]
author: Mark-Yun
title: "UI/UX Audit — 2026-03-26"
---

# UI/UX Audit — 2026-03-26

> Issue #443 · closed · created 2026-03-26T03:10:31Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/443

## Body

## UI/UX Design System Audit — 2026-03-26

### Design Token Violations

#### Hardcoded Colors (6 occurrences, 2 files)

| File | Line | Code |
|------|------|------|
| `apps/app_partner/.../settlement_shimmer.dart` | 59 | `const Color(0xFF3A3A3A)` |
| `apps/app_partner/.../settlement_shimmer.dart` | 60 | `const Color(0xFFE0E0E0)` |
| `apps/app_partner/.../settlement_shimmer.dart` | 62 | `const Color(0xFF4A4A4A)` |
| `apps/app_partner/.../settlement_shimmer.dart` | 63 | `const Color(0xFFF5F5F5)` |
| `shared/.../utils/splash_screen.dart` | 41 | `Color(0xFF21FFFE)` |
| `shared/.../utils/splash_screen.dart` | 166 | `Color(0xFF7B2FBE)` |

#### Hardcoded Font Sizes (16 occurrences, 8 files)

| File | Line | Value |
|------|------|-------|
| `apps/app_partner/.../ticket_list_item.dart` | 169 | `fontSize: 11` |
| `shared/.../auth/ui/staff_gate_screen.dart` | 149 | `fontSize: 10` |
| `shared/.../dev/design_catalog_page.dart` | 178 | `fontSize: 10` |
| `shared/.../dev/dev_user_switch_screen.dart` | 110 | `fontSize: 18` |
| `shared/.../social/ui/minglit_social_action_chip.dart` | 146 | `fontSize: 14` |
| `shared/.../social/ui/minglit_social_button.dart` | 98 | `fontSize: 13` |
| `shared/.../debug/user_session_info.dart` | 51,57,70,79,93 | `fontSize: 11,13` |
| `shared/.../party/event_card.dart` | 260,269,284,335 | `fontSize: 13` |

#### Hardcoded Spacing (101 occurrences, 45 files)

Top offenders (by occurrence count):

| File | Count | Values |
|------|-------|--------|
| `shared/.../bug_reporter_wrapper.dart` | 8 | 4,8,16 |
| `shared/.../auth/ui/minglit_login_screen.dart` | 7 | 8,12,16,48 |
| `shared/.../party/event_card.dart` | 9 | 2,3,4,6 |
| `apps/app_partner/.../settlement_detail_page.dart` | 11 | 8,12,16 |
| `apps/app_partner/.../bank_account_page.dart` | 6 | 8,12,16 |
| `shared/.../permission/app_permission_settings_screen.dart` | 4 | 4,8,16,32 |
| `apps/app_partner/.../download_bottom_sheet.dart` | 3 | 8,24 |
| `apps/app_partner/.../settlement_empty_state.dart` | 3 | 8,16,24 |

*Full list: 45 files across apps/app_partner, apps/app_user, and shared/packages/minglit_kit use numeric literals in SizedBox instead of MinglitSpacing tokens.*

#### Non-standard Buttons (18 occurrences, 15 files)

| File | Line | Type |
|------|------|------|
| `apps/app_user/.../event_bottom_ticket_bar.dart` | 63 | ElevatedButton + style override |
| `apps/app_user/.../matching_vote_screen.dart` | 300 | ElevatedButton + style override |
| `apps/app_user/.../purchase_history_card.dart` | 211,354 | ElevatedButton + style override |
| `apps/app_partner/.../partner_apply_page.dart` | 152,175 | OutlinedButton/ElevatedButton + style override |
| `apps/app_partner/.../partner_welcome_page.dart` | 112 | ElevatedButton + style override |
| `apps/app_partner/.../step1_basic_info.dart` | 119 | OutlinedButton + style override |
| `apps/app_partner/.../step4_documents.dart` | 121 | OutlinedButton + style override |
| `apps/app_partner/.../event_application_review_dialog.dart` | 199 | ElevatedButton + style override |
| `apps/app_partner/.../ticket_manage_screen.dart` | 117 | OutlinedButton + style override |
| `shared/.../minglit_alert.dart` | 68,75 | TextButton + style override |
| `shared/.../partner_detail_view.dart` | 138 | TextButton + style override |
| `shared/.../party_detail_view.dart` | 215 | ElevatedButton + style override |
| `shared/.../design_catalog_page.dart` | 643 | ElevatedButton + style override (catalog demo) |
| `shared/.../minglit_social_button.dart` | 100 | TextButton + style override |
| `shared/.../minglit_login_screen.dart` | 249 | OutlinedButton + style override |
| `shared/.../minglit_global_loading_overlay.dart` | 75 | TextButton + style override |

---

### Golden Test Coverage Gaps

**Coverage: 5 / 48 pages+screens = 10.4%**

#### Covered (5)
- `app_partner/partner_home_page` → `home_page_golden_test.dart`
- `app_partner/party_list_page` → `party_list_page_golden_test.dart`
- `app_user/home_page` → `home_page_golden_test.dart`
- `app_user/my_page` → `my_page_golden_test.dart`
- `app_user/search_page` → `search_page_golden_test.dart`

#### Not Covered — app_partner pages (22)
partner_application_detail_page, partner_application_list_page, partner_login_page, location_guide_page, partner_member_list_page, partner_member_permission_page, more_page, partner_apply_page, partner_apply_status_page, partner_welcome_page, party_create_wizard_page, party_detail_page, event_create_page, event_detail_page, ticket_template_create_page, bank_account_page, settlement_detail_page, settlement_page, ticket_create_page, ticket_edit_page, create_verification_page, verification_manage_page

#### Not Covered — app_user pages (10)
login_page, auth_callback_page, event_application_wizard_page, event_detail_page, partner_detail_page, partner_events_page, party_curation_page, purchase_history_page, blocked_partners_page, privacy_page

#### Not Covered — all screens (13)
qr_scanner_screen (x2), matching_settings_screen, entry_group_editor_screen, ticket_manage_screen, ticket_template_manage_screen, party_basic_info_edit_screen, party_capacity_contact_edit_screen, party_location_edit_screen, review_verification_screen, matching_vote_screen, payment_success_screen, ticket_qr_screen

---

### Doc-Code Consistency

**Undocumented token classes** (exist in `minglit_design_tokens.dart` but missing from `docs/ux/design-system/01-foundation.md`):

| Class | Members |
|-------|---------|
| `MinglitBorders` | `card(ColorScheme, bool isSelected)` |
| `MinglitDecorations` | `selectableCard(BuildContext, bool isSelected)` |
| `MinglitTextStyles` | `selectableCardTitle`, `selectableCardSubtitle`, `selectableCardDescription`, `infoText` |

**Note:** Doc mentions `MinglitElevation` (TODO) but code uses `MinglitShadows` instead — naming mismatch.

---

### Golden Image Visual Analysis (app_user only — app_partner has no golden PNGs)

| Image | Observations |
|-------|-------------|
| `home_page_empty` | Clean empty state, filter chips consistent, good vertical centering |
| `home_page_with_events` | Brand purple gradient on cards, Minglit logo rendered, event card layout consistent |
| `my_page_logged_out` | Good empty state pattern with icon + CTA, purple primary button correctly applied |
| `my_page_logged_in` | Profile section with avatar, settings list well-structured, red logout action properly differentiated |
| `search_page_empty` | Purple-bordered search input, centered empty state icon |

**Visual issues noted:**
- Korean text renders as squares in golden tests (font not loaded in test env) — impacts visual regression reliability
- No dark mode golden variants exist for any page
- No app_partner golden PNGs generated (only test files exist, no actual screenshots)

---

### Summary

| Category | Count |
|----------|-------|
| Hardcoded Colors | 6 |
| Hardcoded Font Sizes | 16 |
| Hardcoded Spacing | 101 |
| Non-standard Buttons | 18 |
| **Total Token Violations** | **141** |
| Golden Test Coverage | 10.4% (5/48) |
| Undocumented Token Classes | 3 |

---
*Generated by audit-uiux worker*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-26

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 2건 → #448 (docs: 디자인 유틸리티 클래스 문서 누락), #449 (test: Golden 테스트 한글 폰트 로딩)
- skip 항목: 5건
  - Hardcoded Colors/Font Sizes/Spacing/Buttons (141건) — 스타일/컨벤션, 기능 영향 없음. #442 report-exec에서 개선 제안으로 이미 다뤄짐
  - Golden Test Coverage 10.4% — 단순 커버리지 비율, 구체적 회귀 버그 아님
  - Dark mode golden 미존재 — #444 report-exec에서 이미 다뤄짐
  - MinglitElevation vs MinglitShadows — 문서에 TODO로 인지됨, 실제 불일치 아님

원본 리포트를 닫습니다.
