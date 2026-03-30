import 'dart:async';

import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_coordinator.g.dart';

@riverpod
TicketCoordinator ticketCoordinator(Ref ref) {
  return TicketCoordinator(ref.read(goRouterProvider));
}

class TicketCoordinator {
  TicketCoordinator(this._router);

  final GoRouter _router;

  void pushEventDetail(String eventId) {
    unawaited(_router.push(EventDetailRoute(eventId: eventId).location));
  }

  // Fix #634: event_coordinator에서 이동 — ticket UI를 ticket feature 내부에서 관리
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
