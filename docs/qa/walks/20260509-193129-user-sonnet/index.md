# Spec Walk 20260509-193129 — app_user

- **Walker**: spec-walk-user-sonnet
- **Device**: Galaxy S10e (SM-G970N)
- **Captured**: 17 unique screens / 17 attempts
- **Spec inventory**: 62 screens defined
- **Test user**: user_18_f_강남@test.com (password1234!)

## Notes
- 로그인 후 캡처 (dev switch로 user_18_f_강남@test.com 로그인)
- EventNowBar overlay 화면 5종 (check-in, checkedIn, matching, results, review) — 현재 활성 이벤트 없어 skipped
- partner-only 화면 — partner app에서 별도 캡처 필요
- 삭제 flow (deletion_reason ~ completion) — 계정 삭제 의도 필요하여 skipped

| Route | screenshot | uidump | spec_diff | drift |
|---|---|---|---|---|
| HomeRoute | [png](home_page/screenshot.png) | [txt](home_page/uidump.txt) | [diff](home_page/spec_diff.md) | 2 |
| SearchRoute | [png](search_page/screenshot.png) | [txt](search_page/uidump.txt) | [diff](search_page/spec_diff.md) | 0 |
| MyPageRoute | [png](my_page/screenshot.png) | [txt](my_page/uidump.txt) | [diff](my_page/spec_diff.md) | 2 |
| PurchaseHistoryRoute | [png](purchase_history_page/screenshot.png) | [txt](purchase_history_page/uidump.txt) | [diff](purchase_history_page/spec_diff.md) | 0 |
| PurchaseHistoryDetailRoute | [png](purchase_history_detail_page/screenshot.png) | [txt](purchase_history_detail_page/uidump.txt) | [diff](purchase_history_detail_page/spec_diff.md) | 0 |
| MyTicketsRoute | [png](my_tickets_page/screenshot.png) | [txt](my_tickets_page/uidump.txt) | [diff](my_tickets_page/spec_diff.md) | 0 |
| NotificationSettingsRoute | [png](notification_settings_screen/screenshot.png) | [txt](notification_settings_screen/uidump.txt) | [diff](notification_settings_screen/spec_diff.md) | 0 |
| PrivacyRoute | [png](privacy_page/screenshot.png) | [txt](privacy_page/uidump.txt) | [diff](privacy_page/spec_diff.md) | 1 |
| AccountManagementRoute | [png](account_management_page/screenshot.png) | [txt](account_management_page/uidump.txt) | [diff](account_management_page/spec_diff.md) | 0 |
| BlockedPartnersRoute | [png](blocked_partners_page/screenshot.png) | [txt](blocked_partners_page/uidump.txt) | [diff](blocked_partners_page/spec_diff.md) | 0 |
| NotificationCenterRoute | [png](notification_list_screen/screenshot.png) | [txt](notification_list_screen/uidump.txt) | [diff](notification_list_screen/spec_diff.md) | 0 |
| EventDetailRoute | [png](event_detail_page/screenshot.png) | [txt](event_detail_page/uidump.txt) | [diff](event_detail_page/spec_diff.md) | 0 |
| PartnerDetailRoute | [png](partner_detail_page/screenshot.png) | [txt](partner_detail_page/uidump.txt) | [diff](partner_detail_page/spec_diff.md) | 0 |
| PartnerEventsRoute | [png](partner_events_page/screenshot.png) | [txt](partner_events_page/uidump.txt) | [diff](partner_events_page/spec_diff.md) | 0 |
| EventApplicationRoute | [png](event_application_wizard_page/screenshot.png) | [txt](event_application_wizard_page/uidump.txt) | [diff](event_application_wizard_page/spec_diff.md) | 0 |
| TagEventListRoute | [png](tag_event_list_page/screenshot.png) | [txt](tag_event_list_page/uidump.txt) | [diff](tag_event_list_page/spec_diff.md) | 0 |
| LoginRoute | [png](login_page/screenshot.png) | [txt](login_page/uidump.txt) | [diff](login_page/spec_diff.md) | 0 |
| partner_home_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_login_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_apply_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_apply_status_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_welcome_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_event_detail_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_member_list_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_member_permission_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| more_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| recurrence_management_screen | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| settlement_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| settlement_detail_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| bank_account_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_create_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_edit_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| ticket_create_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| ticket_edit_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_manage_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| verification_manage_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| create_verification_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_detail_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_list_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_review_carousel_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_review_confirm_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| event_application_review_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| partner_apply_detail_page | (partner app) | (skipped) | (skipped) | skipped: partner-only screen |
| DeletionReasonRoute | (skipped) | (skipped) | (skipped) | skipped: deletion flow — requires account delete intent |
| DeletionInfoRoute | (skipped) | (skipped) | (skipped) | skipped: deletion flow — step 2 |
| DeletionVerifyRoute | (skipped) | (skipped) | (skipped) | skipped: deletion flow — step 3 |
| DeletionCompleteRoute | (skipped) | (skipped) | (skipped) | skipped: deletion flow — step 4 |
| SignupConsentRoute | (skipped) | (skipped) | (skipped) | skipped: only reachable on first login |
| AuthCallbackRoute | (skipped) | (skipped) | (skipped) | skipped: OAuth callback — not interactable |
| EventCheckInRoute | (skipped) | (skipped) | (skipped) | skipped: EventNowBar — requires active checked-in event |
| EventCheckedInRoute | (skipped) | (skipped) | (skipped) | skipped: EventNowBar — requires active checked-in event |
| EventMatchingRoute | (skipped) | (skipped) | (skipped) | skipped: EventNowBar — requires event in matching phase |
| EventResultsRoute | (skipped) | (skipped) | (skipped) | skipped: EventNowBar — requires event in results phase |
| EventReviewRoute | (skipped) | (skipped) | (skipped) | skipped: EventNowBar — requires event in review phase |
| IdentityVerificationRoute | (skipped) | (skipped) | (skipped) | skipped: requires external verification service |
| CheckinPlaceholderRoute | (skipped) | (skipped) | (skipped) | skipped: checkin-only state |
| LocationGuideRoute | (skipped) | (skipped) | (skipped) | skipped: partner app screen |
| TicketQrRoute | (skipped) | (skipped) | (skipped) | skipped: requires event check-in state |
