import 'dart:async';

import 'package:app_partner/src/features/search/location/location_search_page.dart';
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
      const SnackBar(content: Text('파티를 생성하는 중 문제가 발생했습니다.')),
    );
  }

  void goToCreateVerification(String? partnerId) {
    unawaited(
      CreateVerificationRoute(partnerId: partnerId).push<void>(context),
    );
  }

  Future<Location?> goToLocationSearch() async {
    return Navigator.of(context).push<Location>(
      MaterialPageRoute(
        builder: (_) => const LocationSearchPage(),
        fullscreenDialog: true,
      ),
    );
  }
}
