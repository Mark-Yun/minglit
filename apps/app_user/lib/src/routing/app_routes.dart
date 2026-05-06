import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_verify_page.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/auth/ui/auth_callback_page.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/event/matching/ui/event_matching_screen.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/tickets/my_tickets_page.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/detail/partner_events_page.dart';
import 'package:app_user/src/features/payment/ui/event_application_review_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_detail_page.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:app_user/src/features/tag/ui/tag_event_list_page.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:app_user/src/features/tickets/my_tickets_page.dart';
import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'app_routes.g.dart';

// ---------------------------------------------------------------------------
// Top-Level Routes (outside the shell)
// ---------------------------------------------------------------------------

/// **Dev Map Route**: Navigation hub for dev tools (dev flavor only).
/// Path: `/dev`
// Fix #2138: /dev route was missing — UserDevMap not reachable
@TypedGoRoute<DevRoute>(path: '/dev')
class DevRoute extends GoRouteData with $DevRoute {
  const DevRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UserDevMap();
}

/// **Dev User Switch Route**: Screen to switch between test users.
/// Path: `/dev/switch`
@TypedGoRoute<DevUserSwitchRoute>(path: '/dev/switch')
class DevUserSwitchRoute extends GoRouteData with $DevUserSwitchRoute {
  // Fix #1829: propagate `from` so post-login redirect returns to intended page
  const DevUserSwitchRoute({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DevUserSwitchScreen(from: from);
}

/// **Auth Route**: Login Screen.
/// Path: `/login`
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LoginPage(from: from);
}

/// **Signup Consent Route**: Required consent collection screen.
/// Path: `/signup/consent`
@TypedGoRoute<SignupConsentRoute>(path: '/signup/consent')
class SignupConsentRoute extends GoRouteData with $SignupConsentRoute {
  const SignupConsentRoute({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SignupConsentPage(from: from);
}

/// **Auth Callback Route**: Handles OAuth redirects.
/// Path: `/auth/callback`
@TypedGoRoute<AuthCallbackRoute>(path: '/auth/callback')
class AuthCallbackRoute extends GoRouteData with $AuthCallbackRoute {
  const AuthCallbackRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AuthCallbackPage();
}

/// **Event Detail Route**: Detailed information about a specific event.
/// Path: `/events/:eventId`
@TypedGoRoute<EventDetailRoute>(path: '/events/:eventId')
class EventDetailRoute extends GoRouteData with $EventDetailRoute {
  const EventDetailRoute({required this.eventId});

  final String eventId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MinglitPageTransitions.sharedAxisScaled(
        key: state.pageKey,
        child: EventDetailPage(eventId: eventId),
      );
}

/// **Partner Detail Route**: Detailed information about a specific partner.
/// Path: `/partners/:partnerId`
@TypedGoRoute<PartnerDetailRoute>(path: '/partners/:partnerId')
class PartnerDetailRoute extends GoRouteData with $PartnerDetailRoute {
  const PartnerDetailRoute({required this.partnerId});

  final String partnerId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MinglitPageTransitions.sharedAxisScaled(
        key: state.pageKey,
        child: PartnerDetailPage(partnerId: partnerId),
      );
}

/// **Partner Events Route**: Full list of events for a partner.
/// Path: `/partners/:partnerId/events`
// Fix #2137: partnerName removed from route — PartnerEventsPage fetches it
// from partnerDetailProvider so the route is self-sufficient and never throws
// on a missing query param.
@TypedGoRoute<PartnerEventsRoute>(path: '/partners/:partnerId/events')
class PartnerEventsRoute extends GoRouteData with $PartnerEventsRoute {
  const PartnerEventsRoute({required this.partnerId});

  final String partnerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PartnerEventsPage(partnerId: partnerId);
}

/// **Certification Route**: Identity Verification Screen.
/// Path: `/certification`
@TypedGoRoute<CertificationRoute>(path: '/certification')
class CertificationRoute extends GoRouteData with $CertificationRoute {
  const CertificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IdentityVerificationScreen();
  }
}

/// **Event Application Route**: Wizard for event application.
/// Path: `/events/:eventId/apply`
@TypedGoRoute<EventApplicationRoute>(path: '/events/:eventId/apply')
class EventApplicationRoute extends GoRouteData with $EventApplicationRoute {
  const EventApplicationRoute({required this.eventId, this.ticketId});

  final String eventId;
  final String? ticketId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventApplicationWizardPage(eventId: eventId, ticketId: ticketId);
}

@TypedGoRoute<EventMatchingRoute>(path: '/events/:eventId/matching')
class EventMatchingRoute extends GoRouteData with $EventMatchingRoute {
  const EventMatchingRoute({required this.eventId});

  final String eventId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MinglitPageTransitions.sharedAxisScaled(
        key: state.pageKey,
        child: EventMatchingScreen(eventId: eventId),
      );
}

/// **Event Application Confirmation Route**: Success page after payment.
/// Path: `/events/:eventId/apply/complete`
@TypedGoRoute<EventApplicationConfirmationRoute>(
  path: '/events/:eventId/apply/complete',
)
class EventApplicationConfirmationRoute extends GoRouteData
    with $EventApplicationConfirmationRoute {
  const EventApplicationConfirmationRoute({
    required this.eventId,
    this.ticketId,
  });

  final String eventId;
  final String? ticketId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MinglitConfirmationPage(
      title: '참여 신청이 완료됐어요',
      description: '결제가 완료되었고 신청이 접수되었습니다.\n내 티켓에서 진행 상태를 확인할 수 있어요.',
      icon: Icons.check_circle_outline,
      tone: MinglitConfirmationTone.success,
      ctaLabel: '내 티켓 보기',
      onPressed: () => const PurchaseHistoryRoute().go(context),
    );
  }
}

/// **My Tickets Route**: User's ticket list page.
/// Path: `/tickets/my`
@TypedGoRoute<MyTicketsRoute>(path: '/tickets/my')
class MyTicketsRoute extends GoRouteData with $MyTicketsRoute {
  const MyTicketsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MyTicketsPage();
}

/// **Ticket QR Route**: QR code screen for a specific ticket.
/// Path: `/tickets/:ticketId/qr`
///
/// [TicketEventMeta] is passed via [GoRouterState.extra] — not in the URL —
/// so that complex event metadata can be forwarded from callers that already
/// hold the data (e.g. MyTicketsPage) without a round-trip query.
// Fix #1526: $extra 활용해 TicketEventMeta 전달 — URL에 포함 불가한 complex object
@TypedGoRoute<TicketQRRoute>(path: '/tickets/:ticketId/qr')
class TicketQRRoute extends GoRouteData with $TicketQRRoute {
  const TicketQRRoute({required this.ticketId, this.$extra});

  final String ticketId;

  /// Optional event metadata forwarded from the calling screen.
  /// Accessed via [GoRouterState.extra] — not serialized in the URL.
  ///
  // Directive: go_router_builder 4.x does not auto-generate state.extra
  // forwarding. After running build_runner, manually re-apply:
  //   `$extra: state.extra as TicketEventMeta?`
  // in app_routes.g.dart _fromState. See PR #1532.
  final TicketEventMeta? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TicketQRScreen(ticketId: ticketId, eventMeta: $extra);
}

/// **Purchase History Route**
/// Path: `/purchase-history`
@TypedGoRoute<PurchaseHistoryRoute>(path: '/purchase-history')
class PurchaseHistoryRoute extends GoRouteData with $PurchaseHistoryRoute {
  const PurchaseHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PurchaseHistoryPage();
}

/// **Purchase History Detail Route**
/// Path: `/purchase-history/:applicationId`
@TypedGoRoute<PurchaseHistoryDetailRoute>(
  path: '/purchase-history/:applicationId',
)
class PurchaseHistoryDetailRoute extends GoRouteData
    with $PurchaseHistoryDetailRoute {
  const PurchaseHistoryDetailRoute({required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PurchaseHistoryDetailPage(applicationId: applicationId);
}

/// **Event Application Review Route**
/// Path: `/purchase-history/:applicationId/review`
@TypedGoRoute<EventApplicationReviewRoute>(
  path: '/purchase-history/:applicationId/review',
)
class EventApplicationReviewRoute extends GoRouteData
    with $EventApplicationReviewRoute {
  const EventApplicationReviewRoute({required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventApplicationReviewPage(applicationId: applicationId);
}

/// **Notification Center Route**
/// Path: `/notifications`
@TypedGoRoute<NotificationCenterRoute>(path: '/notifications')
class NotificationCenterRoute extends GoRouteData
    with $NotificationCenterRoute {
  const NotificationCenterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationListScreen();
}

/// **Notification Settings Route**
/// Path: `/my/notification-settings`
@TypedGoRoute<NotificationSettingsRoute>(path: '/my/notification-settings')
class NotificationSettingsRoute extends GoRouteData
    with $NotificationSettingsRoute {
  const NotificationSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationSettingsScreen();
}

/// **Account Management Route**: Logout and account deletion sub-settings page.
/// Path: `/my/account`
@TypedGoRoute<AccountManagementRoute>(path: '/my/account')
class AccountManagementRoute extends GoRouteData with $AccountManagementRoute {
  const AccountManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Fix #1213: 계정 관리 서브페이지 — 로그아웃/회원탈퇴 통합
    return Consumer(
      builder: (context, ref, _) {
        return AccountManagementPage(
          onLogout: () {
            // Fix #404: navigate first, then sign out.
            // Future.delayed(Duration.zero) avoids
            // context-after-dispose errors.
            GoRouter.of(context).go('/');
            unawaited(
              Future<void>.delayed(Duration.zero).then((_) {
                unawaited(ref.read(authControllerProvider.notifier).signOut());
              }),
            );
          },
          onDeleteAccount: () {
            // Fix #1213: 기존 회원 탈퇴 플로우를 계정 관리에서 재사용
            ref.read(accountDeletionCoordinatorProvider).start();
          },
          // Fix #1861: 계정 관리에서 본인인증 직접 진입 가능하도록
          onCertification: () =>
              unawaited(context.push(const CertificationRoute().location)),
          isVerified:
              ref.watch(currentUserProfileProvider).asData?.value?.isVerified ??
              false,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shell Routes (promoted to top-level)
// ---------------------------------------------------------------------------

/// **Home Route**: Main Dashboard.
/// Path: `/`
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// **Search Route**: Full-page search screen.
/// Path: `/search`
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SearchPage();
}

/// **My Page Route**
/// Path: `/my`
@TypedGoRoute<MyPageRoute>(path: '/my')
class MyPageRoute extends GoRouteData with $MyPageRoute {
  const MyPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MyPage();
}

/// **Privacy Route**: Privacy settings page.
/// Path: `/my/privacy`
@TypedGoRoute<PrivacyRoute>(path: '/my/privacy')
class PrivacyRoute extends GoRouteData with $PrivacyRoute {
  const PrivacyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacyPage();
}

/// **Deletion Reason Route**: Account deletion reason selection page.
/// Path: `/my/privacy/delete/reason`
@TypedGoRoute<DeletionReasonRoute>(path: '/my/privacy/delete/reason')
class DeletionReasonRoute extends GoRouteData with $DeletionReasonRoute {
  const DeletionReasonRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DeletionReasonPage();
}

/// **Deletion Info Route**: Account deletion 안내 page.
/// Path: `/my/privacy/delete/info`
@TypedGoRoute<DeletionInfoRoute>(path: '/my/privacy/delete/info')
class DeletionInfoRoute extends GoRouteData with $DeletionInfoRoute {
  const DeletionInfoRoute({this.reasonCode, this.reasonText});

  final String? reasonCode;
  final String? reasonText;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DeletionInfoPage(reasonCode: reasonCode, reasonText: reasonText);
}

/// **Deletion Verify Route**: Account deletion verification page.
/// Path: `/my/privacy/delete/verify`
@TypedGoRoute<DeletionVerifyRoute>(path: '/my/privacy/delete/verify')
class DeletionVerifyRoute extends GoRouteData with $DeletionVerifyRoute {
  const DeletionVerifyRoute({this.reasonCode, this.reasonText});

  final String? reasonCode;
  final String? reasonText;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DeletionVerifyPage(reasonCode: reasonCode, reasonText: reasonText);
}

/// **Deletion Complete Route**: Account deletion completion page.
/// Path: `/my/privacy/delete/complete`
@TypedGoRoute<DeletionCompleteRoute>(path: '/my/privacy/delete/complete')
class DeletionCompleteRoute extends GoRouteData with $DeletionCompleteRoute {
  const DeletionCompleteRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DeletionCompletePage();
}

/// **Blocked Partners Route**: Blocked partners list page.
/// Path: `/my/blocked-partners`
@TypedGoRoute<BlockedPartnersRoute>(path: '/my/blocked-partners')
class BlockedPartnersRoute extends GoRouteData with $BlockedPartnersRoute {
  const BlockedPartnersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BlockedPartnersPage();
}

/// **Tag Event List Route**: Paginated event list for a specific tag.
/// Path: `/tags/:tagId`
///
/// [tagName] is passed as a query parameter for AppBar display.
@TypedGoRoute<TagEventListRoute>(path: '/tags/:tagId')
class TagEventListRoute extends GoRouteData with $TagEventListRoute {
  const TagEventListRoute({required this.tagId, required this.tagName});

  final String tagId;
  final String tagName;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TagEventListPage(tagId: tagId, tagName: tagName);
}
