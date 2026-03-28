import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/party/ticket/entry_group_editor_screen.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateCoordinator {
  const PartyCreateCoordinator(this.context, {this.ref});

  final BuildContext context;
  final WidgetRef? ref;

  void onPartyCreated() {
    Navigator.of(context).pop();
  }

  void onError(Object e, [StackTrace? st]) {
    handleMinglitError(context, e, st);
  }

  // Fix #540: await navigation return and invalidate partyVerificationTypesProvider
  // here (party feature) instead of in verification controller (cross-feature).
  Future<void> goToCreateVerification(String? partnerId) async {
    await CreateVerificationRoute(partnerId: partnerId).push<void>(context);
    ref?.invalidate(partyVerificationTypesProvider);
  }

  Future<Location?> goToLocationSearch() async {
    return Navigator.of(context).push<Location>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> goToEntryGroupEditor({
    required void Function(PartyEntryGroup group) onSaved,
    PartyEntryGroup? initialGroup,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EntryGroupEditorScreen(
          initialGroup: initialGroup,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
