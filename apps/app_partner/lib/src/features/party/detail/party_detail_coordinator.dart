import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/search/location/location_search_page.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/error_handler.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
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
          SnackBar(content: Text(context.l10n.partyDetail_message_activated)),
        );
      }
    } on Object catch (e, st) {
      if (context.mounted) {
        handleMinglitError(context, e, st);
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
          SnackBar(content: Text(context.l10n.partyDetail_message_deactivated)),
        );
      }
    } on Object catch (e, st) {
      if (context.mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      loading.hide();
    }
  }

  Future<void> updatePartyEntryGroup(
    String partyId,
    PartyEntryGroup updatedGroup,
    BuildContext context,
  ) async {
    final loading = _ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      final party = await _ref.read(partyDetailProvider(partyId).future);
      final currentGroups = party.entryGroups;

      final updatedGroups = currentGroups
          .map((g) => g.id == updatedGroup.id ? updatedGroup : g)
          .toList();

      await _ref
          .read(partyRepositoryProvider)
          .updateParty(
            party.copyWith(
              conditions: updatedGroups.map((e) => e.toJson()).toList(),
            ),
          );

      _ref.invalidate(partyDetailProvider(partyId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('입장 그룹이 수정되었습니다.')),
        );
      }
    } on Object catch (e, st) {
      if (context.mounted) {
        handleMinglitError(context, e, st);
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
