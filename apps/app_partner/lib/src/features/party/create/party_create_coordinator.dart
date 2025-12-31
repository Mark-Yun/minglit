import 'dart:async';

import 'package:app_partner/src/features/verification/create_verification_screen.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';

class PartyCreateCoordinator {
  const PartyCreateCoordinator(this.context);

  final BuildContext context;

  void onPartyCreated() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파티가 성공적으로 생성되었습니다!')),
    );
    Navigator.of(context).pop();
  }

  void goToCreateVerification(String? partnerId) {
    // If GoRouter is available, use it. Otherwise, use standard Navigator.
    try {
      unawaited(CreateVerificationRoute(partnerId: partnerId).push(context));
    } catch (e) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CreateVerificationScreen(partnerId: partnerId),
          ),
        ),
      );
    }
  }

  void onError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating party: $error')),
    );
  }
}
