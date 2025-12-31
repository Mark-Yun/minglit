import 'dart:async';

import 'package:app_partner/src/features/party/create/location_search_page.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateCoordinator {
  const PartyCreateCoordinator(this.context);

  final BuildContext context;

  void onPartyCreated() {
    Navigator.of(context).pop();
  }

  void onError(Exception e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('에러 발생: $e')),
    );
  }

  void goToCreateVerification(String? partnerId) {
    unawaited(
      CreateVerificationRoute(partnerId: partnerId).push<void>(context),
    );
  }

  Future<PartyLocation?> goToLocationSearch() async {
    return Navigator.of(context).push<PartyLocation>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchPage(),
        fullscreenDialog: true,
      ),
    );
  }
}
