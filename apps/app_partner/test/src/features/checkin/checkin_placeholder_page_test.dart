import 'dart:async';

import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('CheckinPlaceholderPage', () {
    const testPartner = Partner(
      id: 'partner-1',
      name: 'Test Partner',
      contactEmail: 'test@partner.com',
    );

    final now = DateTime.now();
    final testEvent = Event(
      id: 'event-1',
      partyId: 'party-1',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      title: 'Test Event',
    );

    Widget buildWidget({required List<dynamic> overrides}) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: const MaterialApp(home: CheckinPlaceholderPage()),
      );
    }

    testWidgets('shows loading indicator when partner info is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) => Completer<Partner?>().future,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when partner info fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) => Future<Partner?>.error('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('shows message when partner info is null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows empty state when 0 events today', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => <Event>[],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 예정된 이벤트가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    // TODO #1009: 1-event auto-entry test remains disabled.
    // Blocker: QRScannerScreen uses mobile_scanner (currently unpinned as "any"
    // in pubspec.yaml), which has async dispose behavior. Flutter's test framework
    // does not await plugin disposal during teardown, causing flaky test failures.
    // Note: 0-event and 2+-event tests validate UI states, not 1-event routing.
    // When re-enabling this test, ensure it verifies auto-routing behavior
    // (events.length == 1 → direct QRScannerScreen entry).
    //
    // Re-enable when mobile_scanner provides synchronous disposal or when a
    // test shim for camera plugins becomes available.

    testWidgets('shows event selection when 2+ events today', (
      tester,
    ) async {
      final event2 = Event(
        id: 'event-2',
        partyId: 'party-1',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        createdAt: now,
        updatedAt: now,
        title: 'Second Event',
      );

      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => [testEvent, event2],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 선택하세요'), findsOneWidget);
      expect(find.text('오늘 2개 이벤트가 진행됩니다'), findsOneWidget);
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('Second Event'), findsOneWidget);
    });

    testWidgets('shows loading indicator when events are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) => Completer<List<Event>>().future,
            ),
          ],
        ),
      );
      // Pump twice: once for partner resolve, once for events loading state
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error when events fail to load', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) =>
                  Future<List<Event>>.error('Events load failed'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 불러올 수 없습니다'), findsOneWidget);
    });
  });
}
