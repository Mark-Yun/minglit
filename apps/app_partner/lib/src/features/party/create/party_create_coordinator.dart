import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartyCreateCoordinator {
  const PartyCreateCoordinator(this.context);

  final BuildContext context;

  void onPartyCreated() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party created successfully!')),
    );
    context.pop();
  }

  void onError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating party: $error')),
    );
  }
}
