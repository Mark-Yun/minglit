---
source_url: https://github.com/Mark-Yun/minglit/issues/440
captured_at: 2026-03-26
issue_number: 440
state: closed
labels: [audit-report]
author: Mark-Yun
title: "UI/UX Audit — 2026-03-26"
---

# UI/UX Audit — 2026-03-26

> Issue #440 · closed · created 2026-03-26T03:02:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/440

## Body

## UI/UX Design System Audit — 2026-03-26

### Design Token Violations

#### Hardcoded Colors (6 violations, 2 files)

| File | Line | Code |
|------|------|------|
| `apps/app_partner/.../settlement/widgets/settlement_shimmer.dart` | 59 | `const Color(0xFF3A3A3A)` |
| `apps/app_partner/.../settlement/widgets/settlement_shimmer.dart` | 60 | `const Color(0xFFE0E0E0)` |
| `apps/app_partner/.../settlement/widgets/settlement_shimmer.dart` | 62 | `const Color(0xFF4A4A4A)` |
| `apps/app_partner/.../settlement/widgets/settlement_shimmer.dart` | 63 | `const Color(0xFFF5F5F5)` |
| `shared/packages/minglit_kit/.../utils/splash_screen.dart` | 41 | `Color(0xFF21FFFE)` |
| `shared/packages/minglit_kit/.../utils/splash_screen.dart` | 166 | `Color(0xFF7B2FBE)` |

#### Hardcoded Font Sizes (18 violations, 8 files)

| File | Line | Code |
|------|------|------|
| `shared/.../dev/dev_user_switch_screen.dart` | 110 | `fontSize: 18` |
| `shared/.../dev/design_catalog_page.dart` | 178 | `fontSize: 10` |
| `shared/.../auth/ui/staff_gate_screen.dart` | 149 | `fontSize: 10` |
| `shared/.../social/ui/minglit_social_action_chip.dart` | 146 | `fontSize: 14` |
| `shared/.../debug/user_session_info.dart` | 51 | `fontSize: 13` |
| `shared/.../debug/user_session_info.dart` | 57 | `fontSize: 11` |
| `shared/.../debug/user_session_info.dart` | 70 | `fontSize: 11` |
| `shared/.../debug/user_session_info.dart` | 79 | `fontSize: 11` |
| `shared/.../debug/user_session_info.dart` | 93 | `fontSize: 11` |
| `shared/.../party/event_card.dart` | 260 | `fontSize: 13` |
| `shared/.../party/event_card.dart` | 269 | `fontSize: 13` |
| `shared/.../party/event_card.dart` | 284 | `fontSize: 13` |
| `shared/.../party/event_card.dart` | 335 | `fontSize: 13` |
| `apps/app_partner/.../ticket_list_item.dart` | 169 | `fontSize: 11` |
| `shared/.../social/ui/minglit_social_button.dart` | 98 | `fontSize: 13` |

> Note: 3 additional occurrences in files listed above (total 18). Most common: `11` (6x), `13` (6x).

#### Hardcoded Spacing (82 violations, 30+ files)

**Top offenders by file:**

| File | Count | Common Values |
|------|-------|---------------|
| `apps/app_partner/.../settlement/settlement_detail_page.dart` | 11 | 8, 12, 16 |
| `shared/.../party/event_card.dart` | 10 | 2, 3, 4, 6 |
| `shared/.../bug_reporter_wrapper.dart` | 8 | 4, 8, 16 |
| `shared/.../auth/ui/minglit_login_screen.dart` | 8 | 12, 16, 48 |
| `apps/app_partner/.../settlement/bank_account_page.dart` | 6 | 8, 12, 16 |
| `shared/.../permission/app_permission_settings_screen.dart` | 4 | 4, 8, 16, 32 |
| `apps/app_partner/.../home/widgets/upcoming_events_card.dart` | 3 | 2, 4, 8 |

**Most common hardcoded values:** `8` (18x), `4` (16x), `16` (13x), `12` (8x)

<details>
<summary>Full list (82 violations)</summary>

**apps/app_user (5)**
- `purchase_history_card.dart:93` — `SizedBox(height: 4)`
- `ticket_qr_screen.dart:34` — `SizedBox(height: 16)`
- `open_in_app_dialog_test.dart:139` — `SizedBox(width: 8)`
- `open_in_app_dialog_test.dart:147` — `SizedBox(width: 4)`
- `matching_vote_screen.dart:207` — `SizedBox(width: 4)`

**apps/app_partner (36)**
- `partner_home_page.dart:192` — `SizedBox(height: 100)`
- `revenue_summary_card.dart:67` — `SizedBox(height: 8)`
- `upcoming_events_card.dart:41,168,179` — `SizedBox` 2/4/8
- `closing_soon_events_card.dart:42,75` — `SizedBox` 2/8
- `pending_applicants_badge_card.dart:61` — `SizedBox(height: 4)`
- `today_party_card.dart:141,149` — `SizedBox` 4
- `approval_waiting_card.dart:54` — `SizedBox(height: 4)`
- `location_guide_page.dart:101,175` — `SizedBox(width: 8)`
- `active_party_summary_scroll.dart:40,163` — `SizedBox` 4/8
- `settlement_detail_page.dart:69,74,80,108,110,113,148,176,233,261,302` — 11 violations
- `bank_account_page.dart:57,97,216,223,230,238` — 6 violations
- `settlement_shimmer.dart:83,94` — `SizedBox` 8
- `download_bottom_sheet.dart:42,47,59` — `SizedBox` 8/24
- `settlement_card.dart:36,43` — `SizedBox(height: 4)`
- `settlement_empty_state.dart:29,38,48` — `SizedBox` 8/16/24
- `ticket_manage_screen.dart:105` — `SizedBox(height: 2)`
- `event_date_time_input.dart:150,160` — `SizedBox` 4/8
- `event_application_review_dialog.dart:104` — `SizedBox(height: 4)`
- `party_capacity_input.dart:55` — `SizedBox(height: 4)`
- `party_contact_summary.dart:73` — `SizedBox(width: 8)`
- `party_capacity_summary.dart:25` — `SizedBox(width: 8)`
- `party_basic_info_summary.dart:172` — `SizedBox(width: 4)`
- `party_location_summary.dart:120` — `SizedBox(width: 6)`
- `review_verification_screen.dart:103` — `SizedBox(height: 16)`
- `qr_scanner_screen.dart:122` — `SizedBox(height: 24)`
- `address_search_dialog.dart:150` — `SizedBox(width: 8)`

**shared/minglit_kit (41)**
- `location_map_view.dart:116` — `SizedBox(height: 2)`
- `event_card.dart:147,157,240,243,255,264,273,279,328` — 10 violations
- `minglit_file_picker_image_preview.dart:128` — `SizedBox(height: 4)`
- `entry_group_detail.dart:100,114` — `SizedBox(width: 6)`
- `minglit_filter_chip.dart:104` — `SizedBox(width: 4)`
- `minglit_chip.dart:106,112` — `SizedBox(width: 4)`
- `bug_reporter_wrapper.dart:196,199,224,237,246,256,266,329` — 8 violations
- `user_session_info.dart:74,98` — `SizedBox` 12/16
- `certification_web.dart:123` — `SizedBox(height: 16)`
- `minglit_login_screen.dart:85,107,116,127,134,170,267` — 7 violations
- `staff_gate_screen.dart:145` — `SizedBox(width: 4)`
- `notification_list_screen.dart:93,95` — `SizedBox(height: 4)`
- `minglit_social_action_chip.dart:134,142` — `SizedBox(width: 4)`
- `dev_user_switch_screen.dart:107,112` — `SizedBox` 8/16
- `app_permission_settings_screen.dart:173,185,198,277` — 4 violations

</details>

#### Non-standard Buttons (14 violations, 10 files)

| File | Line | Widget | Override |
|------|------|--------|----------|
| `apps/app_user/.../purchase_history_card.dart` | 211 | `ElevatedButton` | `backgroundColor`, `foregroundColor` |
| `apps/app_user/.../purchase_history_card.dart` | 354 | `ElevatedButton` | `backgroundColor`, `foregroundColor` |
| `apps/app_user/.../matching_vote_screen.dart` | 300 | `ElevatedButton` | `backgroundColor`, `foregroundColor`, `padding`, `visualDensity` |
| `apps/app_user/.../event_bottom_ticket_bar.dart` | 63 | `ElevatedButton` | `backgroundColor` |
| `apps/app_partner/.../event_application_review_dialog.dart` | 199 | `ElevatedButton` | `backgroundColor`, `foregroundColor` |
| `apps/app_partner/.../partner_welcome_page.dart` | 112 | `ElevatedButton` | `backgroundColor`, `foregroundColor`, `padding`, `shape` |
| `apps/app_partner/.../partner_apply_page.dart` | 175 | `ElevatedButton` | `backgroundColor`, `foregroundColor`, `padding`, `shape` |
| `shared/.../partner_detail_view.dart` | 138 | `TextButton` | `padding`, `minimumSize`, `tapTargetSize` |
| `shared/.../minglit_alert.dart` | 68 | `TextButton` | `foregroundColor` |
| `shared/.../minglit_alert.dart` | 75 | `TextButton` | `foregroundColor`, `textStyle` |
| `shared/.../minglit_global_loading_overlay.dart` | 75 | `TextButton` | `foregroundColor`, `backgroundColor` |
| `shared/.../minglit_social_button.dart` | 100 | `TextButton` | `padding`, `minimumSize`, `tapTargetSize` |
| `shared/.../design_catalog_page.dart` | 643 | `ElevatedButton` | `backgroundColor` |
| `shared/.../party_detail_view.dart` | 215 | `ElevatedButton` | `minimumSize`, `padding` |

---

### Golden Test Coverage Gaps

**Coverage: 5/48 pages (10.4%)**

| App | Covered | Total | Rate |
|-----|---------|-------|------|
| app_partner | 2 | 34 | 5.9% |
| app_user | 3 | 14 | 21.4% |

<details>
<summary>43 uncovered pages/screens</summary>

**app_partner (32 uncovered)**
- `partner_application_detail_page.dart`
- `partner_application_list_page.dart`
- `partner_login_page.dart`
- `location_guide_page.dart`
- `partner_member_list_page.dart`
- `partner_member_permission_page.dart`
- `more_page.dart`
- `partner_apply_page.dart`
- `partner_apply_status_page.dart`
- `partner_welcome_page.dart`
- `party_create_wizard_page.dart`
- `party_detail_page.dart`
- `event_create_page.dart`
- `event_detail_page.dart`
- `ticket_template_create_page.dart`
- `bank_account_page.dart`
- `settlement_detail_page.dart`
- `settlement_page.dart`
- `ticket_create_page.dart`
- `ticket_edit_page.dart`
- `create_verification_page.dart`
- `verification_manage_page.dart`
- `qr_scanner_screen.dart` (checkin)
- `qr_scanner_screen.dart` (qr)
- `matching_settings_screen.dart`
- `entry_group_editor_screen.dart`
- `ticket_manage_screen.dart`
- `ticket_template_manage_screen.dart`
- `party_basic_info_edit_screen.dart`
- `party_capacity_contact_edit_screen.dart`
- `party_location_edit_screen.dart`
- `review_verification_screen.dart`

**app_user (11 uncovered)**
- `login_page.dart`
- `auth_callback_page.dart`
- `event_application_wizard_page.dart`
- `event_detail_page.dart`
- `partner_detail_page.dart`
- `partner_events_page.dart`
- `party_curation_page.dart`
- `purchase_history_page.dart`
- `blocked_partners_page.dart`
- `privacy_page.dart`
- `matching_vote_screen.dart`
- `payment_success_screen.dart`
- `ticket_qr_screen.dart`

</details>

---

### Doc-Code Consistency

All tokens documented. Foundation doc (`docs/ux/design-system/01-foundation.md`) is up-to-date with `minglit_design_tokens.dart`.

**Noted TODOs in docs (not violations):**
- Typography scale: `bodySmall`, `bodyLarge`, `labelLarge` definitions pending
- Elevation/Shadow: `MinglitElevation` class not yet defined
- Animation Curves: standard curve tokens not yet defined

---

### Summary

| Category | Count |
|----------|-------|
| Hardcoded Colors | 6 |
| Hardcoded Font Sizes | 18 |
| Hardcoded Spacing | 82 |
| Non-standard Buttons | 14 |
| **Total Token Violations** | **120** |
| Golden Test Coverage Gaps | 43/48 pages |
| Undocumented Tokens | 0 |

---
*Generated by audit-uiux worker*
