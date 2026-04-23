// Fix #1733: regression test for the entry-condition tap path on Party Detail.
//
// Before the fix, tapping the "입장 조건" section in PartyRuleManagementTab /
// PartyDetailInfoTab showed a "준비 중" toast (or no-op) instead of navigating
// to the management screen. These tests exercise the actual tap entry points
// and prove that PartyEntryGroupManagementScreen is pushed onto the navigator.
// If someone reverts the entry-point wiring, these tests fail.

import 'package:app_partner/src/features/party/detail/tabs/party_detail_info_tab.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_rule_management_tab.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_entry_group_management_screen.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

Party _makeParty({List<PartyEntryGroup>? entryGroups}) {
  final now = DateTime.now();
  return Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
    entryGroups: entryGroups,
  );
}

class _PushObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushed.add(route);
    }
  }
}

Widget _wrapTab({
  required Widget tab,
  required _PushObserver observer,
  required List<Object> overrides,
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      navigatorObservers: [observer],
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: tab),
    ),
  );
}

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();

    when(() => mockPartyRepo.getPartyById(any())).thenAnswer(
      (_) async => _makeParty(),
    );
    when(
      () => mockTicketRepo.getTicketTemplatesByPartyId(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockLocationRepo.getLocationById(any()),
    ).thenAnswer((_) async => null);
  });

  group('PartyRuleManagementTab entry-condition tap (Fix #1733)', () {
    testWidgets(
      'pushes PartyEntryGroupManagementScreen instead of showing "준비 중" toast',
      (tester) async {
        final observer = _PushObserver();
        final party = _makeParty();

        await tester.pumpWidget(
          _wrapTab(
            tab: PartyRuleManagementTab(party: party),
            observer: observer,
            overrides: [
              partyRepositoryProvider.overrideWithValue(mockPartyRepo),
              ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
            ],
          ),
        );
        // Let the ticket provider resolve and UI render
        await tester.pump();

        // Tap the entry-condition section by its title
        final entranceTitle = find.text(
          AppLocalizations.of(
            tester.element(find.byType(PartyRuleManagementTab)),
          )!.partyDetail_section_entranceCondition,
        );
        expect(entranceTitle, findsOneWidget);
        await tester.tap(entranceTitle);
        await tester.pump();

        // Must push the management screen (not show a toast)
        expect(
          observer.pushed.any((r) {
            if (r is MaterialPageRoute) {
              final w = r.builder(
                tester.element(find.byType(PartyRuleManagementTab)),
              );
              return w is PartyEntryGroupManagementScreen;
            }
            return false;
          }),
          isTrue,
          reason:
              'Tapping the entry-condition section must push '
              'PartyEntryGroupManagementScreen (Fix #1733).',
        );

        // Sanity: no "준비 중" toast content
        expect(find.textContaining('준비 중'), findsNothing);
      },
    );
  });

  group('PartyDetailInfoTab entry-condition tap (Fix #1733)', () {
    testWidgets(
      'pushes PartyEntryGroupManagementScreen on entry-condition section tap',
      (tester) async {
        final observer = _PushObserver();
        final party = _makeParty();

        await tester.pumpWidget(
          _wrapTab(
            tab: PartyDetailInfoTab(party: party),
            observer: observer,
            overrides: [
              partyRepositoryProvider.overrideWithValue(mockPartyRepo),
              locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            ],
          ),
        );
        await tester.pump();

        final entranceTitle = find.text(
          AppLocalizations.of(
            tester.element(find.byType(PartyDetailInfoTab)),
          )!.partyDetail_section_entranceCondition,
        );
        expect(entranceTitle, findsOneWidget);
        // Scroll the section into view before tapping
        await tester.ensureVisible(entranceTitle);
        await tester.pump();
        await tester.tap(entranceTitle);
        await tester.pump();

        expect(
          observer.pushed.any((r) {
            if (r is MaterialPageRoute) {
              final w = r.builder(
                tester.element(find.byType(PartyDetailInfoTab)),
              );
              return w is PartyEntryGroupManagementScreen;
            }
            return false;
          }),
          isTrue,
          reason:
              'Tapping the entry-condition section on the info tab must push '
              'PartyEntryGroupManagementScreen (Fix #1733).',
        );
      },
    );
  });
}
