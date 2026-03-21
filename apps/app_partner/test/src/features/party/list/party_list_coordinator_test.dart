import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartyListCoordinator', () {
    testWidgets('goToCreate navigates without error', (tester) async {
      late PartyListCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = PartyListCoordinator(context);
              return const Scaffold(body: Text('test'));
            },
          ),
        ),
      );

      // goToCreate uses try/catch fallback to Navigator.push.
      // In test environment without GoRouter, it falls back to Navigator.push.
      // This verifies no unhandled exceptions.
      expect(() => coordinator.goToCreate(), returnsNormally);
    });

    testWidgets('goToDetail navigates without error', (tester) async {
      late PartyListCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = PartyListCoordinator(context);
              return const Scaffold(body: Text('test'));
            },
          ),
        ),
      );

      expect(() => coordinator.goToDetail('party-1'), returnsNormally);
    });
  });
}
