import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/search/location/location_search_page.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_detail_coordinator.g.dart';

@riverpod
PartyDetailCoordinator partyDetailCoordinator(Ref ref) {
  return PartyDetailCoordinator(ref);
}

class PartyDetailCoordinator {
  const PartyDetailCoordinator(this._ref);

  final Ref _ref;

  void goToEditParty(String partyId) {
    // TODO(mark): Implement Party Edit Route
    debugPrint('Coordinator: Edit Party $partyId');
  }

  Future<Location?> goToLocationSearch(BuildContext context) async {
    return Navigator.of(context).push<Location>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchPage(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> activateParty(String partyId, BuildContext context) async {
    final loading = _ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await _ref
          .read(partyRepositoryProvider)
          .updatePartyStatus(partyId, 'active');
      _ref.invalidate(partyDetailProvider(partyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파티가 활성화되었습니다.')),
        );
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파티 상태 변경 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      loading.hide();
    }
  }

  Future<void> deactivateParty(String partyId, BuildContext context) async {
    final loading = _ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await _ref
          .read(partyRepositoryProvider)
          .updatePartyStatus(partyId, 'closed');
      _ref.invalidate(partyDetailProvider(partyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파티가 비활성화(보관)되었습니다.')),
        );
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파티 상태 변경 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      loading.hide();
    }
  }

  void goToCreateEvent(String partyId) {
    unawaited(
      _ref
          .read(goRouterProvider)
          .push(EventCreateRoute(partyId: partyId).location),
    );
  }

  void goToEventDetail(String partyId, String eventId) {
    _ref
        .read(goRouterProvider)
        .go(
          EventDetailRoute(partyId: partyId, eventId: eventId).location,
        );
  }

  void goToCreateTicket(String partyId, String eventId) {
    unawaited(
      _ref
          .read(goRouterProvider)
          .push(TicketCreateRoute(partyId: partyId, eventId: eventId).location),
    );
  }
}
