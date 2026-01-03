import 'dart:async';

import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateCoordinator {
  const PartyCreateCoordinator(this.context);

  final BuildContext context;

  void onPartyCreated() {
    Navigator.of(context).pop();
  }

  void onError(Object e, [StackTrace? st]) {
    handleMinglitError(context, e, st);
  }

  void goToCreateVerification(String? partnerId) {
    unawaited(
      CreateVerificationRoute(partnerId: partnerId).push<void>(context),
    );
  }

  Future<Location?> goToLocationSearch() async {
    return Navigator.of(context).push<Location>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
