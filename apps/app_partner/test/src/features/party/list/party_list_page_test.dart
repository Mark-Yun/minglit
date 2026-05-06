// Fix #2200: AppBar info icon → showMinglitHelpSheet. QR scan icon removed.
// Regression: verify the help-sheet CTA is wired and QR is gone.
import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockPartyListCoordinator extends Mock implements PartyListCoordinator {}

void main() {
  Widget buildPage() {
    final coordinator = _MockPartyListCoordinator();
    return ProviderScope(
      overrides: [
        partyListProvider.overrideWith((_) async => <Party>[]),
        partyListCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: const MaterialApp(home: PartyListPage()),
    );
  }

  group('PartyListPage AppBar — info icon (#2200)', () {
    testWidgets('info_outline icon is present, QR icon is absent', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      // QR scan was the old entry point — must be gone after #2200
      expect(find.byIcon(Icons.qr_code), findsNothing);
      expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    });

    testWidgets('tapping info icon opens 파티 관리 가이드 bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('파티 관리 가이드'), findsOneWidget);
    });
  });
}
