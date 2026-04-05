import 'dart:async';

import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_coordinator.g.dart';

@riverpod
EventCoordinator eventCoordinator(Ref ref) {
  return EventCoordinator(ref.read(goRouterProvider));
}

class EventCoordinator {
  EventCoordinator(this._router);

  final GoRouter _router;

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }

  void pushPartnerDetail(String partnerId) {
    unawaited(_router.push(PartnerDetailRoute(partnerId: partnerId).location));
  }

  void goToEventDetail(String eventId) {
    _router.go(EventDetailRoute(eventId: eventId).location);
  }

  void pushEventCuration(EventFeedType type) {
    unawaited(_router.push(EventCurationRoute(type: type).location));
  }

  void goToApplicationWizard(
    String eventId, {
    String? ticketId,
  }) {
    unawaited(
      _router.push(
        EventApplicationRoute(eventId: eventId, ticketId: ticketId).location,
      ),
    );
  }

  // Fix #634: auth_coordinator 직접 참조 → event_coordinator 내부로 login 네비게이션 위임
  void pushLogin({String? from}) {
    unawaited(_router.push(LoginRoute(from: from).location));
  }

  // Fix #1094: home_coordinator 직접 참조 제거 — event feature 내에서 구매내역 네비게이션
  void goToPurchaseHistory() {
    _router.go(const PurchaseHistoryRoute().location);
  }

  // Fix #1094: ticket_coordinator 직접 참조 제거 — event feature 내에서 티켓 선택 UI 관리
  void showTicketSelection(
    BuildContext context,
    Event event, {
    required void Function(String eventId, String? ticketId) onTicketSelected,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TicketSelectionSheet(
          event: event,
          onTicketSelected: onTicketSelected,
        ),
      ),
    );
  }
}
