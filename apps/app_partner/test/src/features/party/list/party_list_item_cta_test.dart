import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/list/party_with_stats.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final baseParty = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget buildItem({
    required PartyWithStats entry,
    VoidCallback? onCreateEventTap,
    VoidCallback? onNextEventTap,
  }) {
    return MaterialApp(
      localizationsDelegates: kPartnerLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PartyListItem(
            entry: entry,
            onTap: () {},
            onCreateEventTap: onCreateEventTap,
            onNextEventTap: onNextEventTap,
          ),
        ),
      ),
    );
  }

  // Regression tests for #2201: CTA buttons were rendered with onPressed: null
  // causing the create-event flow to be silently broken.

  // Regression for #2253: onNextEventTap must fire when _NextEventRow is tapped
  group('PartyListItem CTA — next-event callback wiring', () {
    testWidgets(
      'Variant A (has nextEvent): tapping next-event row calls onNextEventTap',
      (tester) async {
        var called = false;
        final now = DateTime(2026, 5, 10, 20);
        final entry = PartyWithStats(
          party: baseParty,
          completedCount: 0,
          upcomingCount: 1,
          nextEvent: Event(
            id: 'event-1',
            partyId: 'party-1',
            startTime: now.add(const Duration(days: 3)),
            endTime: now.add(const Duration(days: 3, hours: 2)),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          buildItem(entry: entry, onNextEventTap: () => called = true),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.event_available_outlined));
        expect(
          called,
          isTrue,
          reason: '_NextEventRow InkWell must invoke onNextEventTap',
        );
      },
    );
  });

  group('PartyListItem CTA — create-event callback wiring', () {
    testWidgets(
      'Variant C (completed > 0, no upcoming): tapping CTA calls onCreateEventTap',
      (tester) async {
        var called = false;
        final entry = PartyWithStats(
          party: baseParty,
          completedCount: 1,
          upcomingCount: 0,
        );

        await tester.pumpWidget(
          buildItem(entry: entry, onCreateEventTap: () => called = true),
        );
        await tester.pump();

        await tester.tap(find.byType(OutlinedButton));
        expect(
          called,
          isTrue,
          reason: '_CreateEventRow CTA must invoke onCreateEventTap',
        );
      },
    );

    testWidgets(
      'Variant D (brand new, no events): tapping CTA calls onCreateEventTap',
      (tester) async {
        var called = false;
        final entry = PartyWithStats(
          party: baseParty,
          completedCount: 0,
          upcomingCount: 0,
        );

        await tester.pumpWidget(
          buildItem(entry: entry, onCreateEventTap: () => called = true),
        );
        await tester.pump();

        await tester.tap(find.byType(OutlinedButton));
        expect(
          called,
          isTrue,
          reason: '_NewPartyCtaRow CTA must invoke onCreateEventTap',
        );
      },
    );
  });
}
