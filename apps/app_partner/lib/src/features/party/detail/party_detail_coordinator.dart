import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/widgets/party_basic_info_edit_screen.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_contact_edit_screen.dart';
import 'package:app_partner/src/features/party/widgets/party_location_edit_screen.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    unawaited(
      _ref
          .read(goRouterProvider)
          .push(
            PartyEditRoute(partyId: partyId).location,
          ),
    );
  }

  void openBasicInfoEdit(
    BuildContext context, {
    required Party party,
    required void Function(
      String title,
      Map<String, dynamic> description,
      List<String> imageUrls,
      List<XFile> newImages,
      String status,
    )
    onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyBasicInfoEditScreen(
            party: party,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  void openCapacityContactEdit(
    BuildContext context, {
    required Party party,
    required void Function(
      int min,
      int max,
      Map<String, String> options,
    )
    onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyCapacityContactEditScreen(
            party: party,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  void openLocationEdit(
    BuildContext context, {
    required Location? initialLocation,
    required String? initialAddressDetail,
    required String? initialDirectionsGuide,
    required void Function(
      Location? newLoc,
      String addressDetail,
      String directions,
    )
    onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyLocationEditScreen(
            initialLocation: initialLocation,
            initialAddressDetail: initialAddressDetail,
            initialDirectionsGuide: initialDirectionsGuide,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  Future<Location?> goToLocationSearch(BuildContext context) async {
    return Navigator.of(context).push<Location>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(),
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
        context.showMinglitSuccess(context.l10n.partyDetail_message_activated);
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
        context.showMinglitSuccess(
          context.l10n.partyDetail_message_deactivated,
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

      final updatedGroups = (currentGroups ?? [])
          .map((g) => g.id == updatedGroup.id ? updatedGroup : g)
          .toList();

      await _ref
          .read(partyRepositoryProvider)
          .updateParty(
            party.copyWith(
              entryGroups: updatedGroups,
            ),
          );

      _ref.invalidate(partyDetailProvider(partyId));
      if (context.mounted) {
        context.showMinglitSuccess('입장 그룹이 수정되었습니다.');
      }
    } on Object catch (e, st) {
      if (context.mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      loading.hide();
    }
  }

  Future<void> updatePartyCapacityAndContact({
    required String partyId,
    required int minCount,
    required int maxCount,
    required Map<String, dynamic> contactOptions,
    required BuildContext context,
  }) async {
    final loading = _ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      final party = await _ref.read(partyDetailProvider(partyId).future);

      await _ref
          .read(partyRepositoryProvider)
          .updateParty(
            party.copyWith(
              minConfirmedCount: minCount,
              maxParticipants: maxCount,
              contactOptions: contactOptions,
            ),
          );

      _ref.invalidate(partyDetailProvider(partyId));
      if (context.mounted) {
        context.showMinglitSuccess(context.l10n.common_message_saved);
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
        .go(EventDetailRoute(partyId: partyId, eventId: eventId).location);
  }

  void goToCreateTicket(String partyId, String eventId) {
    unawaited(
      _ref
          .read(goRouterProvider)
          .push(TicketCreateRoute(partyId: partyId, eventId: eventId).location),
    );
  }
}
