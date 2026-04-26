// Critical-path tests for PartyDetailCoordinator entry-group mutations and
// capacity/contact updates.
//
// Entry-group operations (add/update/remove) are high-risk because they
// build the full entry_group list, call updateParty, and invalidate
// partyDetailProvider.  An off-by-one or stale-read bug here would silently
// corrupt the party's access rules.
//
// updatePartyCapacityAndContact feeds into capacity limits for event tickets
// and contact routing; a regression breaks partner communications.

import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Party _makeParty(
  String id, {
  List<EntryGroupTemplate>? entryGroups,
  int minConfirmedCount = 5,
  int maxParticipants = 20,
  Map<String, dynamic>? contactOptions,
}) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
    entryGroups: entryGroups ?? [],
    minConfirmedCount: minConfirmedCount,
    maxParticipants: maxParticipants,
    contactOptions: contactOptions ?? {},
  );
}

EntryGroupTemplate _makeGroup(String id, {String gender = 'male'}) {
  return EntryGroupTemplate(
    id: id,
    partyId: 'party-1',
    gender: gender,
  );
}

Widget _buildTestApp({
  required MockPartyRepository mockPartyRepo,
  required String partyId,
  required Party partyInRepo,
  required Widget Function(BuildContext, PartyDetailCoordinator) bodyBuilder,
}) {
  return ProviderScope(
    overrides: [
      partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      partyDetailProvider(partyId).overrideWith(
        (ref) async => partyInRepo,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Consumer(
        builder: (context, ref, _) {
          // Use ref.watch (not ref.read) to keep the coordinator's Ref alive
          // throughout async operations. ref.read lets the auto-dispose provider
          // expire immediately, making the stored _ref invalid mid-call.
          final coordinator = ref.watch(partyDetailCoordinatorProvider);
          return Scaffold(
            body: bodyBuilder(context, coordinator),
          );
        },
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPartyRepository mockPartyRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    // Default stub: updateParty succeeds
    when(
      () => mockPartyRepo.updateParty(
        any(),
        tagIds: any(named: 'tagIds'),
      ),
    ).thenAnswer((_) async => _makeParty('party-1'));
  });

  setUpAll(() {
    registerFallbackValue(
      _makeParty('fallback'),
    );
  });

  // ---------------------------------------------------------------------------
  // addPartyEntryGroup
  // ---------------------------------------------------------------------------
  group('addPartyEntryGroup', () {
    testWidgets(
      'appends the new group to existing groups and calls updateParty',
      (tester) async {
        final existing = _makeGroup('eg-existing');
        final party = _makeParty('party-1', entryGroups: [existing]);
        final newGroup = _makeGroup('eg-new', gender: 'female');

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.addPartyEntryGroup(
                'party-1',
                newGroup,
                context,
              ),
              child: const Text('add'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('add'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        expect(captured, hasLength(1));
        final updatedParty = captured.first as Party;
        expect(updatedParty.entryGroups, hasLength(2));
        expect(
          updatedParty.entryGroups!.any((g) => g.id == 'eg-existing'),
          isTrue,
        );
        expect(
          updatedParty.entryGroups!.any((g) => g.id == 'eg-new'),
          isTrue,
        );
      },
    );

    testWidgets(
      'correctly sets partyId on the new group before persisting',
      (tester) async {
        // The group passed in may have an empty partyId from the editor;
        // addPartyEntryGroup must copyWith(partyId: partyId).
        final group = const EntryGroupTemplate(id: 'eg-1', partyId: '');
        final party = _makeParty('party-1');

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () =>
                  coordinator.addPartyEntryGroup('party-1', group, context),
              child: const Text('add'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('add'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        final updatedParty = captured.first as Party;
        final savedGroup = updatedParty.entryGroups!.first;
        // partyId must be filled in — not the empty string from the editor
        expect(savedGroup.partyId, 'party-1');
      },
    );

    testWidgets('does not crash when updateParty throws', (tester) async {
      when(
        () => mockPartyRepo.updateParty(any()),
      ).thenThrow(Exception('DB error'));

      final party = _makeParty('party-1');

      await tester.pumpWidget(
        _buildTestApp(
          mockPartyRepo: mockPartyRepo,
          partyId: 'party-1',
          partyInRepo: party,
          bodyBuilder: (context, coordinator) => ElevatedButton(
            onPressed: () => coordinator.addPartyEntryGroup(
              'party-1',
              _makeGroup('eg-1'),
              context,
            ),
            child: const Text('add'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('add'));
      await tester.pumpAndSettle();

      // Widget should still be visible — no crash
      expect(find.text('add'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // updatePartyEntryGroup
  // ---------------------------------------------------------------------------
  group('updatePartyEntryGroup', () {
    testWidgets(
      'replaces the matching group and preserves all other groups',
      (tester) async {
        final g1 = _makeGroup('eg-1', gender: 'male');
        final g2 = _makeGroup('eg-2', gender: 'female');
        final party = _makeParty('party-1', entryGroups: [g1, g2]);

        final updatedG1 =
            g1.copyWith(gender: 'mixed', birthYearMin: 1990);

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.updatePartyEntryGroup(
                'party-1',
                updatedG1,
                context,
              ),
              child: const Text('update'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('update'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        final updatedParty = captured.first as Party;
        expect(updatedParty.entryGroups, hasLength(2));

        final savedG1 = updatedParty.entryGroups!.firstWhere(
          (g) => g.id == 'eg-1',
        );
        expect(savedG1.gender, 'mixed');
        expect(savedG1.birthYearMin, 1990);

        // eg-2 must be unchanged
        final savedG2 = updatedParty.entryGroups!.firstWhere(
          (g) => g.id == 'eg-2',
        );
        expect(savedG2.gender, 'female');
      },
    );

    testWidgets(
      'is a no-op on the list when id is not found (does not add new group)',
      (tester) async {
        // updatePartyEntryGroup maps over existing groups: if no id matches, the
        // map produces the same list (no new entry added).
        final g1 = _makeGroup('eg-1');
        final party = _makeParty('party-1', entryGroups: [g1]);
        final phantom = _makeGroup('eg-not-exist');

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.updatePartyEntryGroup(
                'party-1',
                phantom,
                context,
              ),
              child: const Text('update'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('update'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        final updatedParty = captured.first as Party;
        // Length unchanged — phantom group was not appended
        expect(updatedParty.entryGroups, hasLength(1));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // removePartyEntryGroup
  // ---------------------------------------------------------------------------
  group('removePartyEntryGroup', () {
    testWidgets(
      'removes the matching group and keeps the rest',
      (tester) async {
        final g1 = _makeGroup('eg-1');
        final g2 = _makeGroup('eg-2');
        final party = _makeParty('party-1', entryGroups: [g1, g2]);

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.removePartyEntryGroup(
                'party-1',
                'eg-1',
                context,
              ),
              child: const Text('remove'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('remove'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        final updatedParty = captured.first as Party;
        expect(updatedParty.entryGroups, hasLength(1));
        expect(updatedParty.entryGroups!.first.id, 'eg-2');
      },
    );

    testWidgets(
      'removing the only group results in empty entry groups list',
      (tester) async {
        final g1 = _makeGroup('eg-only');
        final party = _makeParty('party-1', entryGroups: [g1]);

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.removePartyEntryGroup(
                'party-1',
                'eg-only',
                context,
              ),
              child: const Text('remove'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('remove'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        final updatedParty = captured.first as Party;
        expect(updatedParty.entryGroups, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updatePartyCapacityAndContact
  // ---------------------------------------------------------------------------
  group('updatePartyCapacityAndContact', () {
    testWidgets(
      'persists correct min/max/contact values via updateParty',
      (tester) async {
        final party = _makeParty(
          'party-1',
          minConfirmedCount: 5,
          maxParticipants: 20,
          contactOptions: {'phone': '010-0000-0000'},
        );

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.updatePartyCapacityAndContact(
                partyId: 'party-1',
                minCount: 10,
                maxCount: 40,
                contactOptions: {'kakao': 'link-123'},
                context: context,
              ),
              child: const Text('save'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('save'));
        await tester.pumpAndSettle();

        final captured =
            verify(() => mockPartyRepo.updateParty(captureAny())).captured;
        expect(captured, hasLength(1));
        final updated = captured.first as Party;
        expect(updated.minConfirmedCount, 10);
        expect(updated.maxParticipants, 40);
        expect(updated.contactOptions, {'kakao': 'link-123'});
      },
    );

    testWidgets(
      'shows success snackbar after successful save',
      (tester) async {
        final party = _makeParty('party-1');

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.updatePartyCapacityAndContact(
                partyId: 'party-1',
                minCount: 5,
                maxCount: 20,
                contactOptions: {},
                context: context,
              ),
              child: const Text('save'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('save'));
        await tester.pumpAndSettle();

        // AppLocalizations 'common_message_saved' = '저장되었습니다.'
        expect(find.text('저장되었습니다.'), findsOneWidget);
      },
    );

    testWidgets(
      'does not crash when updateParty throws',
      (tester) async {
        when(
          () => mockPartyRepo.updateParty(any()),
        ).thenThrow(Exception('write failed'));

        final party = _makeParty('party-1');

        await tester.pumpWidget(
          _buildTestApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            partyInRepo: party,
            bodyBuilder: (context, coordinator) => ElevatedButton(
              onPressed: () => coordinator.updatePartyCapacityAndContact(
                partyId: 'party-1',
                minCount: 5,
                maxCount: 20,
                contactOptions: {},
                context: context,
              ),
              child: const Text('save'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('save'));
        await tester.pumpAndSettle();

        expect(find.text('save'), findsOneWidget);
      },
    );
  });
}
