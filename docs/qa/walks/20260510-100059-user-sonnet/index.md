# Spec Walk 20260510-100059 — app_user

- **Walker**: spec-walk-user-sonnet
- **Device**: Galaxy S10e (SM-G970N)
- **Captured**: 20 unique screens / 20 attempts
- **Spec inventory**: 62 screens defined

## 도달 불가 화면 (SKIPPED)

- auth_callback_page — OAuth redirect, 직접 트리거 불가
- signup_consent_page — 신규 회원 전용, 기존 계정으로 미도달
- deletion_complete_page — 실제 탈퇴 완료 필요 (QA 계정 보존)
- event_application_wizard_page — 재로그인 필요 (Kakao OAuth 자동화 불가)
- event_check_in_screen — 진행 중 이벤트 체크인 상태 필요
- event_checked_in_screen — 체크인 완료 상태 필요
- event_matching_screen — 매칭 단계 이벤트 필요
- event_results_screen — 결과 공개 단계 이벤트 필요
- event_review_screen — 리뷰 단계 이벤트 필요
- identity_verification_screen — 재로그인 필요
- purchase_history_detail_page — 상세 보기 진입점 미확인
- partner_apply_page — 파트너 앱 전용 (user 앱 범위 외)
- partner_apply_status_page — 파트너 앱 전용

| Route | screenshot | uidump | spec_diff | drift |
|---|---|---|---|---|
| HomeRoute | [png](home_page/screenshot.png) | [txt](home_page/uidump.txt) | [diff](home_page/spec_diff.md) | 2 |
| SearchRoute | [png](search_page/screenshot.png) | [txt](search_page/uidump.txt) | [diff](search_page/spec_diff.md) | 0 |
| NotificationCenterRoute | [png](notification_list_screen/screenshot.png) | [txt](notification_list_screen/uidump.txt) | [diff](notification_list_screen/spec_diff.md) | 0 |
| MyPageRoute | [png](my_page/screenshot.png) | [txt](my_page/uidump.txt) | [diff](my_page/spec_diff.md) | 1 |
| MyTicketsRoute | [png](my_tickets_page/screenshot.png) | [txt](my_tickets_page/uidump.txt) | [diff](my_tickets_page/spec_diff.md) | 1 |
| TicketQRRoute | [png](ticket_qr_screen/screenshot.png) | [txt](ticket_qr_screen/uidump.txt) | [diff](ticket_qr_screen/spec_diff.md) | 1 |
| PurchaseHistoryRoute | [png](purchase_history_page/screenshot.png) | [txt](purchase_history_page/uidump.txt) | [diff](purchase_history_page/spec_diff.md) | 1 |
| NotificationSettingsRoute | [png](notification_settings_screen/screenshot.png) | [txt](notification_settings_screen/uidump.txt) | [diff](notification_settings_screen/spec_diff.md) | 0 |
| AccountManagementRoute | [png](account_management_page/screenshot.png) | [txt](account_management_page/uidump.txt) | [diff](account_management_page/spec_diff.md) | 0 |
| PrivacyRoute | [png](privacy_page/screenshot.png) | [txt](privacy_page/uidump.txt) | [diff](privacy_page/spec_diff.md) | 0 |
| DeletionReasonRoute | [png](deletion_reason_page/screenshot.png) | [txt](deletion_reason_page/uidump.txt) | [diff](deletion_reason_page/spec_diff.md) | 0 |
| DeletionInfoRoute | [png](deletion_info_page/screenshot.png) | [txt](deletion_info_page/uidump.txt) | [diff](deletion_info_page/spec_diff.md) | 1 |
| DeletionVerifyRoute | [png](deletion_verify_page/screenshot.png) | [txt](deletion_verify_page/uidump.txt) | [diff](deletion_verify_page/spec_diff.md) | 0 |
| BlockedPartnersRoute | [png](blocked_partners_page/screenshot.png) | [txt](blocked_partners_page/uidump.txt) | [diff](blocked_partners_page/spec_diff.md) | 0 |
| EventDetailRoute | [png](event_detail_page/screenshot.png) | [txt](event_detail_page/uidump.txt) | [diff](event_detail_page/spec_diff.md) | 1 |
| PartnerDetailRoute | [png](partner_detail_page/screenshot.png) | [txt](partner_detail_page/uidump.txt) | [diff](partner_detail_page/spec_diff.md) | 0 |
| PartnerEventsRoute | [png](partner_events_page/screenshot.png) | [txt](partner_events_page/uidump.txt) | [diff](partner_events_page/spec_diff.md) | 0 |
| TagEventListRoute | [png](tag_event_list_page/screenshot.png) | [txt](tag_event_list_page/uidump.txt) | [diff](tag_event_list_page/spec_diff.md) | 0 |
| LoginRoute | [png](login_page/screenshot.png) | [txt](login_page/uidump.txt) | [diff](login_page/spec_diff.md) | 1 |
