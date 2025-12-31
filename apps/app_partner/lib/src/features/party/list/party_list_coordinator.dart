import 'dart:async';

import 'package:app_partner/src/features/party/create/party_create_screen.dart';
import 'package:app_partner/src/features/party/detail/party_detail_page.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';

class PartyListCoordinator {
  const PartyListCoordinator(this.context);

  final BuildContext context;

  void goToCreate() {
    try {
      unawaited(const PartyCreateRoute().push<void>(context));
    } on Object {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PartyCreateScreen(),
          ),
        ),
      );
    }
  }

  void goToDetail(String partyId) {
    try {
      unawaited(PartyDetailRoute(partyId: partyId).push<void>(context));
    } on Object {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PartyDetailPage(partyId: partyId),
          ),
        ),
      );
    }
  }
}
