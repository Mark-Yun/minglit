# Graph Report - apps/app_user + supabase  (2026-04-25)

## Corpus Check
- 432 files · ~353,196 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3005 nodes · 5464 edges · 66 communities detected
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 612 edges (avg confidence: 0.81)
- Token cost: 9,800 input · 1,850 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Feature Files (Mixed)|Feature Files (Mixed)]]
- [[_COMMUNITY_Account Deletion & Admissions|Account Deletion & Admissions]]
- [[_COMMUNITY_AI Adapters (EmbeddingLLM)|AI Adapters (Embedding/LLM)]]
- [[_COMMUNITY_Auth & Account Lifecycle UI|Auth & Account Lifecycle UI]]
- [[_COMMUNITY_Cross-cutting Methods Hub|Cross-cutting Methods Hub]]
- [[_COMMUNITY_Feature Coordinators & Controllers|Feature Coordinators & Controllers]]
- [[_COMMUNITY_Edge Function Handlers|Edge Function Handlers]]
- [[_COMMUNITY_Home & EventNow UI|Home & EventNow UI]]
- [[_COMMUNITY_EF Logger & Auth Utilities|EF Logger & Auth Utilities]]
- [[_COMMUNITY_Localization & TagPayment Pages|Localization & Tag/Payment Pages]]
- [[_COMMUNITY_Account Deletion Pages & Tests|Account Deletion Pages & Tests]]
- [[_COMMUNITY_EF Test Runner Framework|EF Test Runner Framework]]
- [[_COMMUNITY_App Entry & Bootstrap|App Entry & Bootstrap]]
- [[_COMMUNITY_Boarding Pass & Ticket Logic|Boarding Pass & Ticket Logic]]
- [[_COMMUNITY_Consent Flow|Consent Flow]]
- [[_COMMUNITY_QR Ticket UI|QR Ticket UI]]
- [[_COMMUNITY_Iamport Payment Client|Iamport Payment Client]]
- [[_COMMUNITY_Backend Simulator Routes|Backend Simulator Routes]]
- [[_COMMUNITY_Purchase History UI|Purchase History UI]]
- [[_COMMUNITY_SimAction Hierarchy|SimAction Hierarchy]]
- [[_COMMUNITY_Retention & Archival Helpers|Retention & Archival Helpers]]
- [[_COMMUNITY_Event Detail Content|Event Detail Content]]
- [[_COMMUNITY_Event Refund Policy UI|Event Refund Policy UI]]
- [[_COMMUNITY_Golden Capture & Visual QA|Golden Capture & Visual QA]]
- [[_COMMUNITY_CUJ Scenarios|CUJ Scenarios]]
- [[_COMMUNITY_Ticket Selection Widgets|Ticket Selection Widgets]]
- [[_COMMUNITY_Matching Vote UI|Matching Vote UI]]
- [[_COMMUNITY_Eligibility Test Factories|Eligibility Test Factories]]
- [[_COMMUNITY_Patrol Smoke Tests|Patrol Smoke Tests]]
- [[_COMMUNITY_Verification Wizard Step|Verification Wizard Step]]
- [[_COMMUNITY_Event Detail Skeleton UI|Event Detail Skeleton UI]]
- [[_COMMUNITY_Event Bottom Ticket Bar|Event Bottom Ticket Bar]]
- [[_COMMUNITY_Wizard Widgets|Wizard Widgets]]
- [[_COMMUNITY_App Startup & Config|App Startup & Config]]
- [[_COMMUNITY_Flutter Test Setup|Flutter Test Setup]]
- [[_COMMUNITY_Purchase History Card|Purchase History Card]]
- [[_COMMUNITY_Wizard Payment Step|Wizard Payment Step]]
- [[_COMMUNITY_Event Entry Conditions|Event Entry Conditions]]
- [[_COMMUNITY_Share Utils|Share Utils]]
- [[_COMMUNITY_Allure Test Reporter|Allure Test Reporter]]
- [[_COMMUNITY_Event Info Tile|Event Info Tile]]
- [[_COMMUNITY_Event Verification Section|Event Verification Section]]
- [[_COMMUNITY_Allure Helper|Allure Helper]]
- [[_COMMUNITY_Purchase Refund Row|Purchase Refund Row]]
- [[_COMMUNITY_Event Admission State|Event Admission State]]
- [[_COMMUNITY_Admission Action Handler|Admission Action Handler]]
- [[_COMMUNITY_Quill Viewer|Quill Viewer]]
- [[_COMMUNITY_Web Stub Shim|Web Stub Shim]]
- [[_COMMUNITY_Localizations Wrapper|Localizations Wrapper]]
- [[_COMMUNITY_Integration Test Driver|Integration Test Driver]]
- [[_COMMUNITY_Ticket Event Meta|Ticket Event Meta]]
- [[_COMMUNITY_Boarding Pass Status|Boarding Pass Status]]
- [[_COMMUNITY_ID Verification Consent Sheet|ID Verification Consent Sheet]]
- [[_COMMUNITY_Trending Tag Section|Trending Tag Section]]
- [[_COMMUNITY_Notification Settings|Notification Settings]]
- [[_COMMUNITY_App User README|App User README]]
- [[_COMMUNITY_Minglit App Shell|Minglit App Shell]]
- [[_COMMUNITY_Screenshot Scenario|Screenshot Scenario]]
- [[_COMMUNITY_Match Rules RPC|Match Rules RPC]]
- [[_COMMUNITY_App Icon Asset|App Icon Asset]]
- [[_COMMUNITY_Splash Icon Asset|Splash Icon Asset]]
- [[_COMMUNITY_Android Splash Asset|Android Splash Asset]]
- [[_COMMUNITY_Icon Foreground Asset|Icon Foreground Asset]]
- [[_COMMUNITY_Lounge Photo (Seed)|Lounge Photo (Seed)]]
- [[_COMMUNITY_Cafe Photo (Seed) 1|Cafe Photo (Seed) 1]]
- [[_COMMUNITY_Cafe Photo (Seed) 2|Cafe Photo (Seed) 2]]

## God Nodes (most connected - your core abstractions)
1. `package:minglit_kit/minglit_kit.dart` - 158 edges
2. `package:flutter/material.dart` - 128 edges
3. `package:flutter_test/flutter_test.dart` - 117 edges
4. `package:mocktail/mocktail.dart` - 68 edges
5. `dart:async` - 62 edges
6. `Unified Observability Logger (Sentry+Axiom)` - 54 edges
7. `Test Utilities: mock_http` - 54 edges
8. `Supabase Client (Service Role)` - 50 edges
9. `Edge Function Auth Utils` - 47 edges
10. `Response Utils` - 45 edges

## Surprising Connections (you probably didn't know these)
- `logFn()` --calls--> `log()`  [INFERRED]
  /Users/mark/workspace/minglit-graphify-init/supabase/functions/backend-simulator/index.ts → /Users/mark/workspace/minglit-graphify-init/supabase/functions/_shared/axiom_logger.ts
- `updatePolicyRunResult()` --calls--> `captureException()`  [INFERRED]
  /Users/mark/workspace/minglit-graphify-init/supabase/functions/cleanup-retention/index.ts → /Users/mark/workspace/minglit-graphify-init/supabase/functions/_shared/logger.ts
- `uploadSeedImages()` --calls--> `log()`  [INFERRED]
  /Users/mark/workspace/minglit-graphify-init/supabase/functions/dev-seed/index.ts → /Users/mark/workspace/minglit-graphify-init/supabase/functions/_shared/axiom_logger.ts
- `requireServiceRole()` --calls--> `errorResponse()`  [INFERRED]
  /Users/mark/workspace/minglit-graphify-init/supabase/functions/_shared/auth_utils.ts → /Users/mark/workspace/minglit-graphify-init/supabase/functions/_shared/response_utils.ts
- `FakeAccountDeletionController` --semantically_similar_to--> `EventApplicationController (Wizard State Machine)`  [INFERRED] [semantically similar]
  /Users/mark/workspace/minglit-graphify-init/apps/app_user/test/alchemist/scenarios/account_deletion_scenarios.dart → /Users/mark/workspace/minglit-graphify-init/apps/app_user/lib/src/features/event/admission/event_application_controller.dart

## Hyperedges (group relationships)
- **Account Deletion Multi-Step Wizard** — deletion_reason_page, deletion_info_page, deletion_verify_page, deletion_complete_page, account_deletion_coordinator [EXTRACTED 0.95]
- **Parallel App Cold-Start Initialization** — app_startup_provider, supabase_backend, firebase_options, statsig_analytics [EXTRACTED 0.95]
- **OAuth Redirect + Return URL Flow** — login_page, auth_callback_page, auth_coordinator, auth_return_url_pattern [EXTRACTED 0.90]
- **Event Application Wizard Flow** — event_admission_controller, event_application_wizard_page, event_application_controller [INFERRED 0.88]
- **Wizard Step Widgets** — wizard_verification_step, wizard_payment_step, wizard_widgets [EXTRACTED 0.95]
- **Event Detail Content Sections** — event_entry_conditions_section, event_verification_section, event_refund_policy_section [INFERRED 0.90]
- **EventNow Lifecycle Flow** — event_now_bar_controller, event_now_bar, event_now_bottom_sheet [EXTRACTED 0.95]
- **EventNow Phase Content Widgets** — check_in_ready_content, checked_in_content, matching_content, results_content [EXTRACTED 0.95]
- **HomePage Widget Composition** — home_page, event_now_bar, featured_tag_chip_bar, trending_tag_section [EXTRACTED 0.90]
- **Coordinator Pattern: Feature-Isolated Navigation** — partner_coordinator, party_coordinator, search_coordinator, tag_coordinator, payment_coordinator, ticket_coordinator [INFERRED 0.90]
- **Refund Flow: Controller + Policy + Calculator** — purchase_history_controller, policy_repository, refund_calculator [EXTRACTED 1.00]
- **QR Ticket Navigation with EventMeta** — my_tickets_page, home_coordinator, ticket_event_meta [EXTRACTED 1.00]
- **Ticket QR Display Flow** — ticket_qr_screen, boarding_pass_card, ticket_event_meta [EXTRACTED 0.95]
- **Ticket Selection + Recommendation Flow** — ticket_selection_sheet, ticket_recommendation_util, eligibility_filter [INFERRED 0.85]
- **Explore Feed Filter Pipeline** — feed_state_provider, eligibility_filter, explore_filter_chip_bar [EXTRACTED 0.90]
- **Patrol Test Harness** — patrol_test_app, patrol_smoke_test, patrol_flow_search_test [EXTRACTED 0.90]
- **Routing to Ticket QR with Metadata** — app_routes, ticket_qr_screen, ticket_event_meta [EXTRACTED 0.92]
- **Golden Test Pipeline: Scenarios → Helpers → Test** — golden_test_helpers, screenshot_scenario, golden_page_wrapper [EXTRACTED 1.00]
- **All User Scenarios Aggregation** — all_user_scenarios, account_deletion_scenarios, blocked_partners_scenarios [EXTRACTED 1.00]
- **Event Detail + Admission + Policy Golden Flow** — event_detail_scenarios, event_admission_controller, policy_repository [EXTRACTED 0.90]
- **Account Deletion Wizard UI Flow** — deletion_info_page, deletion_reason_page, deletion_verify_page [INFERRED 0.85]
- **Golden Test Scenario Pipeline** — screenshot_scenario, home_scenarios, login_scenarios, matching_vote_scenarios [INFERRED 0.85]
- **Auth Route Guard Flow** — auth_protected_routes, auth_redirect_test, login_page [INFERRED 0.90]
- **Consent Route Guard Flow** — consent_protected_routes, consent_redirect_test, signup_consent_page [INFERRED 0.90]
- **Account Deletion Wizard Flow** — account_deletion_coordinator, deletion_reason_page, deletion_info_page [EXTRACTED 0.95]
- **EventNowBar State Machine** — event_now_bar, event_now_bar_state, event_now_bottom_sheet [EXTRACTED 0.95]
- **Event Application Flow** — event_detail_controller, event_application_controller, event_application_wizard_page [EXTRACTED 0.90]
- **Matching Vote Flow** — matching_vote_controller, matching_vote_content, matching_vote_screen [INFERRED 0.80]
- **QR Ticket CUJ: WalletRepo → TokenService → QRScreen** — ticket_wallet_repository, ticket_token_service, ticket_qr_screen [EXTRACTED 0.90]
- **Admission Button Flow: AdmissionController → EventDetailController → EventDetailPage** — event_admission_controller, event_detail_controller, event_detail_page [INFERRED 0.85]
- **Ticket Application Wizard: AdmissionController → ApplicationController → TicketSelectionSheet** — event_admission_controller, event_application_controller, ticket_selection_sheet [INFERRED 0.85]
- **Account Deletion Flow: ReasonPage → Coordinator → InfoPage** — deletion_reason_page, account_deletion_coordinator, deletion_info_page [EXTRACTED 0.90]
- **Integration Test Infrastructure: TestApp + TestMocks + GoldenCapture** — test_app, test_mocks, golden_capture [EXTRACTED 0.95]
- **Event Admission State Resolution Flow** — event_admission_controller, event_repository, user_repository [EXTRACTED 0.95]
- **Signup Consent Flow** — signup_consent_page, consent_coordinator, consent_repository [INFERRED 0.85]
- **Event Application Payment Flow** — event_application_controller, iamport_controller, event_repository [EXTRACTED 0.90]
- **Ticket Eligibility & Recommendation** — ticket_recommendation_util, eligibility_filter, bulk_eligibility_data [INFERRED 0.80]
- **EventDetailPage Provider Dependencies** — event_detail_controller, event_admission_controller, event_detail_now_provider [EXTRACTED 0.90]
- **EventNowBar Full Flow (controller + widget + bottom sheet)** — event_now_bar_controller, event_now_bar_widget, event_now_bottom_sheet_widget [INFERRED 0.85]
- **Explore Filter Pipeline (filters model + eligibility + feed provider)** — explore_filters_model, eligibility_filter, feed_state_provider [INFERRED 0.85]
- **Coordinator Pattern (home + partner + party coordinators use GoRouter)** — home_coordinator, partner_coordinator, party_coordinator [INFERRED 0.80]
- **HomePage EventNow Stack (page + bar + multi-stack)** — home_page_widget, event_now_bar_widget, event_now_multi_stack_widget [INFERRED 0.80]
- **MyTickets Feature (controller + page + card)** — my_tickets_controller, my_tickets_page_widget, my_ticket_card_widget [INFERRED 0.85]
- **Payment History Test Suite (controller + card + screen + smoke)** — purchase_history_controller_test, purchase_history_card_test, purchase_history_screen_test, purchase_history_smoke_test [INFERRED 0.85]
- **Ticket Feature Test Suite (wallet + status + coordinator + card)** — ticket_wallet_repository_test, boarding_pass_status_test, ticket_coordinator_test, boarding_pass_card_test [INFERRED 0.85]
- **Routing Test Suite (redirect + router + snapshot + 404)** — app_router_redirect_test, app_router_test, app_routes_snapshot_test, route_not_found_error_handler_test [INFERRED 0.85]
- **Shared Test Infrastructure** — test_mocks, test_utils, auto_label_allure_reporter [INFERRED 0.80]
- **PII-Safe Logging Pipeline** — shared_pii_masker, shared_axiom_logger, shared_logger [EXTRACTED 0.95]
- **Payment Verification Flow** — ef_payment_verify, shared_iamport_client, shared_auth_utils [INFERRED 0.85]
- **Payment Cancel/Refund Flow** — ef_payment_cancel, shared_refund_utils, shared_iamport_client [INFERRED 0.85]
- **Contract Schema Validation Layer** — contract_test, shared_json_schemas, test_utils_schema_validator [EXTRACTED 0.90]
- **AI Adapter Pattern (Interface + Factory + Impl)** — ai_embedding_adapter, ai_factory, adapter_openai_embedding [INFERRED 0.90]
- **LLM Adapter Pattern (Interface + Factory + Impl)** — ai_llm_adapter, ai_factory, adapter_openai_llm [INFERRED 0.90]
- **Edge Function Test Infrastructure** — test_utils_mock_http, test_utils_std_server_stub, test_utils_fixtures [INFERRED 0.85]
- **ai-embed Worker Processing Flow** — shared_worker_utils, adapter_openai_embedding, ai_embed_test [INFERRED 0.82]
- **PGMQ Vector Embedding Pipeline** — aiembed_index, shared_worker_utils, db_party_embeddings [INFERRED 0.90]
- **PGMQ Tag Extraction Pipeline** — aiextracttags_index, shared_worker_utils, db_party_tags [INFERRED 0.90]
- **Backend Simulator 6-Phase E2E Flow** — backendsim_index, backendsim_sim_create, backendsim_sim_approve [EXTRACTED 0.95]
- **Event Checkin-Match-Complete Lifecycle** — backendsim_sim_event, backendsim_sim_assertions, backendsim_sim_auth [EXTRACTED 0.90]
- **Apply-Event Free/Paid Application Flow** — applyevent_index, db_event_applications, shared_auth_utils [INFERRED 0.85]
- **Tick Orchestration Pipeline** — sim_tick, partner_action_factory, user_action_factory, action_runner [EXTRACTED 0.95]
- **Partner Action Implementations** — partner_action_approve, partner_action_reject, partner_action_create [EXTRACTED 0.95]
- **User Action Implementations** — user_action_apply, user_action_refund, user_action_checkin, user_action_vote [EXTRACTED 0.95]
- **Dev-Only Environment Guard Shared Pattern** — dev_mock_portone_index, dev_seed_index, dev_session_switch_index, dev_only_guard_pattern [EXTRACTED 1.00]
- **Service Role Auth Protected Functions** — cleanup_blocked_dis_index, cleanup_retention_index, event_matching_index, github_stats_sync_index, shared_auth_utils [EXTRACTED 1.00]
- **Event Check-in and Matching Flow** — event_checkin_index, event_matching_index, db_table_event_participants, db_table_match_pairs, db_table_entry_groups [INFERRED 0.90]
- **Retention Policy Cleanup Pipeline** — cleanup_retention_index, db_table_retention_policies, db_table_retention_policy_audit, rpc_delete_old_rows [EXTRACTED 1.00]
- **Shared Edge Function Utilities** — shared_response_utils, shared_auth_utils, shared_logger, shared_supabase_client, shared_request_utils [INFERRED 0.95]
- **Partner EFs: shared auth+permission guard pattern** — partner_manage_event_index, partner_manage_match_index, partner_manage_member_index, partner_manage_party_index, partner_manage_settlement_index, partner_manage_verification_index, partner_approve_application_index, shared_auth_utils, shared_partner_permissions [INFERRED 0.90]
- **notification-worker PGMQ consume+FCM+DB write flow** — notification_worker_index, db_table_q_notifications, db_table_fcm_tokens, db_table_user_notifications [EXTRACTED 1.00]
- **Event create: entry groups + tickets from templates** — partner_manage_event_index, db_table_entry_group_templates, db_table_entry_groups, db_table_ticket_templates, db_table_tickets [EXTRACTED 0.95]
- **Party create: RPC atomic party+tags write** — partner_manage_party_index, rpc_create_party_with_tags, db_table_parties, db_table_tags [EXTRACTED 0.95]
- **Partner registration: draft→submit→approve lifecycle** — partner_register_index, partner_approve_application_index, db_table_partner_applications [INFERRED 0.85]
- **Payment Pipeline: verify → webhook → cancel** — payment_verify_fn, payment_webhook_fn, payment_cancel_fn [INFERRED 0.85]
- **Recurrence Event Generation: rules CRUD → cron batch → DB** — recurrence_rules_fn, recurrence_cron_fn, table_events [INFERRED 0.82]
- **Partner Management: sync → reject-application → review-submission** — partner_sync_fn, partner_reject_application_fn, partner_review_submission_fn [INFERRED 0.75]
- **Settlement Reconciliation: payout-sync → reconciliation-daily → settlement_items** — payout_sync_fn, reconciliation_daily_fn, table_settlement_items [INFERRED 0.82]
- **User Deletion Compliance: pending deletions → archive → blocked_dis** — process_pending_deletions_fn, table_archived_records, table_blocked_dis [EXTRACTED 0.90]
- **Settlement PortOne Pipeline (query + register + transfer)** — settlement_query_fn, settlement_register_transfers_fn, settlement_transfer_fn [INFERRED 0.90]
- **Order Lifecycle Flow (create → cancel → refund)** — user_create_order_fn, user_cancel_order_fn, shared_refund_utils [INFERRED 0.88]
- **Account Deletion + Cancellation Flow** — user_delete_account_fn, user_cancel_deletion_fn, db_user_profiles [INFERRED 0.92]
- **Vote Eligibility Check Flow (event + participant + ticket + rules)** — user_cast_vote_fn, db_event_participants, db_match_rules [INFERRED 0.87]
- **Nearby Feed with Location Compliance (auth + rate-limit + log)** — user_event_feed_fn, db_location_access_log, location_law_compliance [EXTRACTED 0.95]
- **Verification Data Pipeline: update → submit → review** — user_update_verification_index, user_submit_verification_index, db_user_verifications [INFERRED 0.85]
- **Social Report Flow: block + report + report_details** — user_manage_social_index, db_social_interactions, db_report_details [EXTRACTED 1.00]
- **Edge Functions Shared Infrastructure** — shared_supabase_client, shared_auth_utils, shared_logger [INFERRED 0.80]

## Communities

### Community 0 - "Feature Files (Mixed)"
Cohesion: 0.01
Nodes (357): dart:convert, ../../integration/utils/test_mocks.dart, package:app_user/src/features/auth/login_page.dart, package:app_user/src/features/event/admission/event_admission_controller.dart, package:app_user/src/features/event/admission/event_application_controller.dart, package:app_user/src/features/event/admission/event_application_wizard_page.dart, package:app_user/src/features/event/detail/event_detail_page.dart, package:app_user/src/features/event/logic/event_detail_controller.dart (+349 more)

### Community 1 - "Account Deletion & Admissions"
Cohesion: 0.02
Nodes (294): AccountDeletionController, AccountDeletionCoordinator, Account Deletion Flow (reason options & helpers), Account Deletion Golden Test, Account Deletion 7-day Grace Period Policy, AccountDeletionScenarios, AccountRepository, AdmissionActions Extension (Button Config) (+286 more)

### Community 2 - "AI Adapters (Embedding/LLM)"
Cohesion: 0.02
Nodes (270): OpenAIEmbedding Adapter, OpenAILLM Adapter, ai-embed Function Test, EmbeddingAdapter Interface, Embedding Adapter Test, AI Adapter Factory, AI Factory Test, LLMAdapter Interface (+262 more)

### Community 3 - "Auth & Account Lifecycle UI"
Cohesion: 0.01
Nodes (224): ../golden_test_helpers.dart, package:alchemist/alchemist.dart, package:app_user/main.dart, package:app_user/src/common/widgets/status_badge.dart, package:app_user/src/features/auth/logic/auth_coordinator.dart, package:app_user/src/features/event/admission/payment_success_screen.dart, package:app_user/src/features/event/detail/html_stub.dart, package:app_user/src/features/event/matching/widgets/matching_vote_content.dart (+216 more)

### Community 4 - "Cross-cutting Methods Hub"
Cohesion: 0.01
Nodes (25): authedJsonRequest(), authedTextRequest(), HybridCalculator, serviceRoleRequest(), createBroadMock(), getHandler(), isSingleQuery(), wrapSingle() (+17 more)

### Community 5 - "Feature Coordinators & Controllers"
Cohesion: 0.02
Nodes (138): dart:async, package:app_user/src/features/account_deletion/account_deletion_flow.dart, package:app_user/src/features/home/widgets/event_now_phases/results_content.dart, package:app_user/src/features/party/logic/party_coordinator.dart, package:app_user/src/features/payment/logic/payment_coordinator.dart, package:app_user/src/features/search/logic/search_coordinator.dart, package:app_user/src/features/ticket/logic/ticket_coordinator.dart, package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart (+130 more)

### Community 6 - "Edge Function Handlers"
Cohesion: 0.04
Nodes (88): requireAuth(), log(), addDays(), generateEvents(), getAffectedUserId(), handleApprove(), handleBulkApprove(), handleCancel() (+80 more)

### Community 7 - "Home & EventNow UI"
Cohesion: 0.01
Nodes (132): package:app_user/src/common/event_ticket_token_provider.dart, package:app_user/src/common/widgets/matching_vote_content.dart, package:app_user/src/common/widgets/ticket_qr_viewer.dart, package:app_user/src/features/home/widgets/event_now_bar_controller.dart, package:app_user/src/features/home/widgets/event_now_bar.dart, package:app_user/src/features/home/widgets/event_now_bottom_sheet.dart, package:app_user/src/features/home/widgets/event_now_phases/check_in_ready_content.dart, package:app_user/src/features/home/widgets/event_now_phases/checked_in_content.dart (+124 more)

### Community 8 - "EF Logger & Auth Utilities"
Cohesion: 0.04
Nodes (26): requireServiceRole(), flush(), _restoreBuffer(), checkAllFunctions(), requireEnv(), validateEnv(), calculateDates(), checkAuth() (+18 more)

### Community 9 - "Localization & Tag/Payment Pages"
Cohesion: 0.02
Nodes (101): app_localizations.dart, ../../../../integration/utils/test_app.dart, package:app_user/src/features/event/detail/event_detail_now_provider.dart, package:app_user/src/features/event/detail/open_in_app_dialog.dart, package:app_user/src/features/event/detail/report_bottom_sheet.dart, package:app_user/src/features/event/logic/event_coordinator.dart, package:app_user/src/features/tag/logic/tag_coordinator.dart, package:app_user/src/features/ticket/logic/ticket_recommendation_util.dart (+93 more)

### Community 10 - "Account Deletion Pages & Tests"
Cohesion: 0.02
Nodes (93): package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart, package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart, package:app_user/src/features/account_deletion/ui/deletion_info_page.dart, package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart, package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart, package:app_user/src/features/auth/ui/auth_callback_page.dart, package:app_user/src/features/settings/privacy_page.dart, build (+85 more)

### Community 11 - "EF Test Runner Framework"
Cohesion: 0.04
Nodes (12): ActionRunner, TestAction, PartnerActionApprove, PartnerActionCreateEvent, PartnerActionFactory, shuffle(), UserActionApplyEvent, UserActionCheckin (+4 more)

### Community 12 - "App Entry & Bootstrap"
Cohesion: 0.03
Nodes (57): app_localizations_ko.dart, package:app_user/firebase_options.dart, package:app_user/src/l10n/generated/app_localizations.dart, package:firebase_core/firebase_core.dart, package:flutter_localizations/flutter_localizations.dart, package:flutter_native_splash/flutter_native_splash.dart, package:flutter/widgets.dart, package:sentry_flutter/sentry_flutter.dart (+49 more)

### Community 13 - "Boarding Pass & Ticket Logic"
Cohesion: 0.03
Nodes (55): dart:math, package:app_user/src/features/ticket/logic/boarding_pass_status.dart, clearTokenCache(), _boardingBadge, BoardingPassCard, _BoardingPassCardState, boardingPassStatus, build (+47 more)

### Community 14 - "Consent Flow"
Cohesion: 0.05
Nodes (39): package:app_user/src/features/consent/logic/consent_coordinator.dart, package:app_user/src/features/consent/ui/consent_detail_sheet.dart, package:app_user/src/features/consent/ui/signup_consent_page.dart, _AllConsentTile, build, _ConsentDefinition, _ConsentItemTile, _ConsentTag (+31 more)

### Community 15 - "QR Ticket UI"
Cohesion: 0.05
Nodes (37): package:app_user/src/features/ticket/data/ticket_token_service.dart, package:app_user/src/features/ticket/ui/widgets/boarding_pass_card.dart, package:qr_flutter/qr_flutter.dart, package:screen_brightness/screen_brightness.dart, build, Column, dispose, initState (+29 more)

### Community 16 - "Iamport Payment Client"
Cohesion: 0.09
Nodes (11): IamportClient, getAccessToken(), json(), parseRequestBody(), readJson(), PortoneV2Client, executeRefund(), simCreateGitHubIssue() (+3 more)

### Community 17 - "Backend Simulator Routes"
Cohesion: 0.11
Nodes (9): authRoute(), candidateParticipantRoute(), candidateTicketRoute(), eventRoute(), happyPathRoutes(), matchRulesRoute(), rpcCastVoteRoute(), voterParticipantRoute() (+1 more)

### Community 18 - "Purchase History UI"
Cohesion: 0.09
Nodes (20): build, Container, _DragHandle, EndedContent, GestureDetector, Padding, Row, SizedBox (+12 more)

### Community 19 - "SimAction Hierarchy"
Cohesion: 0.23
Nodes (22): ActionRunner, action_runner_test, PartnerActionApprove, PartnerActionCreateEvent, PartnerActionFactory, PartnerActionReject, SimAction Abstract Base, sim_refund_test (+14 more)

### Community 20 - "Retention & Archival Helpers"
Cohesion: 0.24
Nodes (20): optionalAuth(), addMonths(), addYears(), applyRetentionSpec(), blockedDiExists(), buildArchivedRecords(), deleteAuthUser(), insertArchivedRecords() (+12 more)

### Community 21 - "Event Detail Content"
Cohesion: 0.11
Nodes (17): build, ColoredBox, dispose, Divider, _EventDetailContent, _EventDetailContentState, Function, initState (+9 more)

### Community 22 - "Event Refund Policy UI"
Cohesion: 0.12
Nodes (15): build, _buildCutoffBanner, _buildGracePeriodBanner, _buildLoadingContent, _buildPolicyRow, _buildSummary, Column, Container (+7 more)

### Community 23 - "Golden Capture & Visual QA"
Cohesion: 0.15
Nodes (13): dart:io, dart:typed_data, dart:ui, GoldenCapture, capture, _captureScreenshot, _captureWidgetTree, _ensureFile (+5 more)

### Community 24 - "CUJ Scenarios"
Cohesion: 0.14
Nodes (13): account_deletion_scenarios.dart, blocked_partners_scenarios.dart, event_application_scenarios.dart, event_detail_scenarios.dart, home_scenarios.dart, login_scenarios.dart, matching_vote_scenarios.dart, my_page_scenarios.dart (+5 more)

### Community 25 - "Ticket Selection Widgets"
Cohesion: 0.14
Nodes (13): _buildBalanceBadge, buildEmptyState, buildLoadingState, buildQuantityStepper, _buildRecommendedBadge, buildTicketOption, calculateTotal, Container (+5 more)

### Community 26 - "Matching Vote UI"
Cohesion: 0.15
Nodes (12): build, _buildCandidateCard, _buildMatchCard, Card, Center, ColoredBox, Column, Container (+4 more)

### Community 27 - "Eligibility Test Factories"
Cohesion: 0.17
Nodes (11): EntryGroup, Event, main, makeEvent, makeProfile, makeTicket, maleAgeRestrictedEvent, maleOnlyEvent (+3 more)

### Community 28 - "Patrol Smoke Tests"
Cohesion: 0.18
Nodes (7): package:patrol/patrol.dart, main, main, main, main, main, utils/patrol_test_app.dart

### Community 29 - "Verification Wizard Step"
Cohesion: 0.17
Nodes (11): build, _buildFormField, Center, Column, MinglitAsyncValueWidget, MinglitFilePicker, Padding, SizedBox (+3 more)

### Community 30 - "Event Detail Skeleton UI"
Cohesion: 0.17
Nodes (11): build, ColoredBox, CustomScrollView, Divider, _EventDetailContentSkeleton, MinglitSkeleton, Row, shouldRebuild (+3 more)

### Community 31 - "Event Bottom Ticket Bar"
Cohesion: 0.2
Nodes (9): _BottomTicketBar, _BottomTicketBarSkeleton, build, _buildActionButton, Column, Container, MinglitButton, _showTicketSelection (+1 more)

### Community 32 - "Wizard Widgets"
Cohesion: 0.22
Nodes (8): build, _buildCircle, Column, Container, _Footer, Padding, SizedBox, _StepIndicator

### Community 33 - "App Startup & Config"
Cohesion: 0.28
Nodes (9): appStartupProvider (Riverpod), app_user main() entry point, OG Meta Tag Edge API, Firebase per-environment config split (dev/prod), DefaultFirebaseOptions (env-split config), Parallel Supabase+Firebase+Statsig cold-start optimization rationale, Sentry Flutter (error monitoring), StatsigAnalytics (feature flags & events) (+1 more)

### Community 34 - "Flutter Test Setup"
Cohesion: 0.25
Nodes (8): FlutterTestConfig (Alchemist + NotoSansKR), MinglitApp (main.dart), Patrol: flow_search_test, Patrol: kakao_login_test, Patrol: payment_pg_test, Patrol: permission_grant_test, Patrol: smoke_test, PatrolTestApp helper

### Community 35 - "Purchase History Card"
Cohesion: 0.29
Nodes (6): build, Container, Divider, PurchaseHistoryCard, _showRefundErrorDialog, SizedBox

### Community 36 - "Wizard Payment Step"
Cohesion: 0.33
Nodes (5): build, Column, Divider, _PaymentStep, SizedBox

### Community 37 - "Event Entry Conditions"
Cohesion: 0.33
Nodes (5): build, _EntryConditionsSection, MinglitSection, SizedBox, Stack

### Community 38 - "Share Utils"
Cohesion: 0.33
Nodes (5): package:share_plus/share_plus.dart, eventShareText, eventUrl, _normalizeBaseUrl, ShareUtils

### Community 39 - "Allure Test Reporter"
Cohesion: 0.4
Nodes (4): package:test_reporter/test_reporter.dart, AutoLabelAllureReporter, create, utils/auto_label_allure_reporter.dart

### Community 40 - "Event Info Tile"
Cohesion: 0.4
Nodes (4): build, _InfoTile, Row, SizedBox

### Community 41 - "Event Verification Section"
Cohesion: 0.4
Nodes (4): build, MinglitSection, MinglitSkeleton, _VerificationSection

### Community 42 - "Allure Helper"
Cohesion: 0.5
Nodes (3): package:allure_report/allure_report.dart, package:allure_report/src/test_report.dart, AutoLabelAllureReporter

### Community 43 - "Purchase Refund Row"
Cohesion: 0.5
Nodes (3): build, Padding, _RefundRow

### Community 44 - "Event Admission State"
Cohesion: 0.5
Nodes (3): AdmissionButtonConfig, AdmissionState, _checkEligibility

### Community 45 - "Admission Action Handler"
Cohesion: 0.67
Nodes (2): AdmissionButtonConfig, buttonConfig

### Community 46 - "Quill Viewer"
Cohesion: 0.67
Nodes (2): build, _QuillViewer

### Community 47 - "Web Stub Shim"
Cohesion: 0.67
Nodes (2): Navigator, Window

### Community 48 - "Localizations Wrapper"
Cohesion: 0.67
Nodes (3): AppLocalizations, AppLocalizationsKo, AppLocalizationsX BuildContext extension

### Community 49 - "Integration Test Driver"
Cohesion: 1.0
Nodes (1): package:integration_test/integration_test_driver.dart

### Community 50 - "Ticket Event Meta"
Cohesion: 1.0
Nodes (1): TicketEventMeta

### Community 51 - "Boarding Pass Status"
Cohesion: 1.0
Nodes (1): boardingPassStatus

### Community 52 - "ID Verification Consent Sheet"
Cohesion: 1.0
Nodes (2): IdentityVerificationConsentSheet, IdentityVerificationConsentSheet Test

### Community 53 - "Trending Tag Section"
Cohesion: 1.0
Nodes (2): TrendingTagSection Widget Test, TrendingTagSection Widget

### Community 54 - "Notification Settings"
Cohesion: 1.0
Nodes (2): NotificationSettingsController, NotificationSettingsController Test

### Community 57 - "App User README"
Cohesion: 1.0
Nodes (1): App User README

### Community 58 - "Minglit App Shell"
Cohesion: 1.0
Nodes (1): MinglitApp StatelessWidget

### Community 59 - "Screenshot Scenario"
Cohesion: 1.0
Nodes (1): ScreenshotScenario class

### Community 60 - "Match Rules RPC"
Cohesion: 1.0
Nodes (1): DB: match_rules / replace_match_rules RPC

### Community 61 - "App Icon Asset"
Cohesion: 1.0
Nodes (1): Minglit app icon: purple-to-violet gradient speech bubble with white cursive 'm' and orange sparkle accent

### Community 62 - "Splash Icon Asset"
Cohesion: 1.0
Nodes (1): App splash icon: purple-to-magenta gradient chat bubble with white cursive 'm' and orange sparkle accent

### Community 63 - "Android Splash Asset"
Cohesion: 1.0
Nodes (1): Android 12 splash screen icon — purple-to-magenta gradient speech bubble with white 'm' letter and orange sparkle star; app logo/splash asset

### Community 64 - "Icon Foreground Asset"
Cohesion: 1.0
Nodes (1): App icon foreground: purple gradient speech bubble with white 'm' lettermark and orange sparkle, used as adaptive icon foreground layer for app_user

### Community 65 - "Lounge Photo (Seed)"
Cohesion: 1.0
Nodes (1): Premium lounge/restaurant interior — elegant dining room with dark velvet chairs, wooden tables set with tableware, central bar with shelved display, chandeliers, and East Asian ink paintings; dev-seed fixture image

### Community 66 - "Cafe Photo (Seed) 1"
Cohesion: 1.0
Nodes (1): Bright airy cafe/lounge interior with numbered wooden tables, plants, and string lights — dev-seed fixture image for party venue seeding

### Community 67 - "Cafe Photo (Seed) 2"
Cohesion: 1.0
Nodes (1): Warm sunlit cafe interior with wooden tables, chairs, plants, string lights, and menu board — dev-seed party venue fixture image

## Ambiguous Edges - Review These
- `AuthCoordinator` → `AuthCoordinator`  [AMBIGUOUS]
  /Users/mark/workspace/minglit-graphify-init/apps/app_user/lib/src/features/auth/logic/auth_coordinator.dart · relation: semantically_similar_to

## Knowledge Gaps
- **1490 isolated node(s):** `package:integration_test/integration_test_driver.dart`, `_loadNotoSansKR`, `_NoFiltersNotifier`, `main`, `build` (+1485 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Admission Action Handler`** (3 nodes): `admission_action_handler.dart`, `AdmissionButtonConfig`, `buttonConfig`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Quill Viewer`** (3 nodes): `event_quill_viewer.dart`, `build`, `_QuillViewer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Web Stub Shim`** (3 nodes): `html_stub.dart`, `Navigator`, `Window`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Integration Test Driver`** (2 nodes): `integration_test.dart`, `package:integration_test/integration_test_driver.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Ticket Event Meta`** (2 nodes): `ticket_event_meta.dart`, `TicketEventMeta`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Boarding Pass Status`** (2 nodes): `boarding_pass_status.dart`, `boardingPassStatus`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ID Verification Consent Sheet`** (2 nodes): `IdentityVerificationConsentSheet`, `IdentityVerificationConsentSheet Test`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Trending Tag Section`** (2 nodes): `TrendingTagSection Widget Test`, `TrendingTagSection Widget`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Notification Settings`** (2 nodes): `NotificationSettingsController`, `NotificationSettingsController Test`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App User README`** (1 nodes): `App User README`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Minglit App Shell`** (1 nodes): `MinglitApp StatelessWidget`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Screenshot Scenario`** (1 nodes): `ScreenshotScenario class`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Match Rules RPC`** (1 nodes): `DB: match_rules / replace_match_rules RPC`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Icon Asset`** (1 nodes): `Minglit app icon: purple-to-violet gradient speech bubble with white cursive 'm' and orange sparkle accent`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Splash Icon Asset`** (1 nodes): `App splash icon: purple-to-magenta gradient chat bubble with white cursive 'm' and orange sparkle accent`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Splash Asset`** (1 nodes): `Android 12 splash screen icon — purple-to-magenta gradient speech bubble with white 'm' letter and orange sparkle star; app logo/splash asset`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Icon Foreground Asset`** (1 nodes): `App icon foreground: purple gradient speech bubble with white 'm' lettermark and orange sparkle, used as adaptive icon foreground layer for app_user`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Lounge Photo (Seed)`** (1 nodes): `Premium lounge/restaurant interior — elegant dining room with dark velvet chairs, wooden tables set with tableware, central bar with shelved display, chandeliers, and East Asian ink paintings; dev-seed fixture image`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Cafe Photo (Seed) 1`** (1 nodes): `Bright airy cafe/lounge interior with numbered wooden tables, plants, and string lights — dev-seed fixture image for party venue seeding`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Cafe Photo (Seed) 2`** (1 nodes): `Warm sunlit cafe interior with wooden tables, chairs, plants, string lights, and menu board — dev-seed party venue fixture image`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `AuthCoordinator` and `AuthCoordinator`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **Why does `package:minglit_kit/minglit_kit.dart` connect `Feature Files (Mixed)` to `Auth & Account Lifecycle UI`, `Feature Coordinators & Controllers`, `Home & EventNow UI`, `Localization & Tag/Payment Pages`, `Account Deletion Pages & Tests`, `App Entry & Bootstrap`, `Boarding Pass & Ticket Logic`, `Consent Flow`, `QR Ticket UI`, `Purchase History UI`, `Matching Vote UI`, `Eligibility Test Factories`?**
  _High betweenness centrality (0.183) - this node is a cross-community bridge._
- **Why does `Text` connect `Iamport Payment Client` to `Localization & Tag/Payment Pages`, `Edge Function Handlers`?**
  _High betweenness centrality (0.182) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `Auth & Account Lifecycle UI` to `Feature Files (Mixed)`, `Feature Coordinators & Controllers`, `Home & EventNow UI`, `Localization & Tag/Payment Pages`, `Account Deletion Pages & Tests`, `App Entry & Bootstrap`, `Boarding Pass & Ticket Logic`, `Consent Flow`, `QR Ticket UI`, `Purchase History UI`, `Matching Vote UI`, `Patrol Smoke Tests`?**
  _High betweenness centrality (0.133) - this node is a cross-community bridge._
- **What connects `package:integration_test/integration_test_driver.dart`, `_loadNotoSansKR`, `_NoFiltersNotifier` to the rest of the system?**
  _1490 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Feature Files (Mixed)` be split into smaller, more focused modules?**
  _Cohesion score 0.01 - nodes in this community are weakly interconnected._
- **Should `Account Deletion & Admissions` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._