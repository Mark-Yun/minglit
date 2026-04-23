// Fix #1733: regression tests for entry group add/update/remove in PartyDetailCoordinator
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

PartyEntryGroup _makeGroup(String id) {
  final now = DateTime.now();
  return PartyEntryGroup(
    id: id,
    partyId: 'party-1',
    createdAt: now,
    updatedAt: now,
  );
}

/// Builds a ProviderScope widget for coordinator tests, captures BuildContext.
Future<({ProviderContainer container, BuildContext ctx})> _buildScope(
  WidgetTester tester, {
  required MockPartyRepository mockRepo,
  required MockGoRouter mockRouter,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partyRepositoryProvider.overrideWithValue(mockRepo),
        goRouterProvider.overrideWithValue(mockRouter),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (ctx) {
            captured = ctx;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    ),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(captured);
  return (container: container, ctx: captured);
}

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockGoRouter mockRouter;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockRouter = MockGoRouter();
    registerFallbackValue(_makeParty());
    // Fix #1733: Route fallback required by Mocktail any() in verify()
    registerFallbackValue(
      MaterialPageRoute<dynamic>(
        builder: (_) => const SizedBox.shrink(),
      ),
    );
  });

  group('PartyDetailCoordinator.addPartyEntryGroup', () {
    testWidgets('appends new group to party and calls updateParty', (
      tester,
    ) async {
      final existing = _makeGroup('g-1');
      final newGroup = _makeGroup('g-2');

      when(() => mockPartyRepo.getPartyById('party-1')).thenAnswer(
        (_) async => _makeParty(entryGroups: [existing]),
      );
      when(
        () => mockPartyRepo.updateParty(any()),
      ).thenAnswer((_) async => _makeParty());

      final (:container, :ctx) = await _buildScope(
        tester,
        mockRepo: mockPartyRepo,
        mockRouter: mockRouter,
      );
      // Preload partyDetailProvider cache
      final sub = container.listen(partyDetailProvider('party-1'), (_, _) {});
      addTearDown(sub.close);
      await tester.pump(const Duration(milliseconds: 100));

      await container
          .read(partyDetailCoordinatorProvider)
          .addPartyEntryGroup('party-1', newGroup, ctx);

      final captured = verify(
        () => mockPartyRepo.updateParty(captureAny()),
      ).captured;
      final updatedParty = captured.first as Party;
      expect(updatedParty.entryGroups, hasLength(2));
      expect(
        updatedParty.entryGroups!.map((g) => g.id).toList(),
        containsAll(['g-1', 'g-2']),
      );
    });
  });

  group('PartyDetailCoordinator.removePartyEntryGroup', () {
    testWidgets('removes the specified group and calls updateParty', (
      tester,
    ) async {
      final groupA = _makeGroup('g-A');
      final groupB = _makeGroup('g-B');

      when(() => mockPartyRepo.getPartyById('party-1')).thenAnswer(
        (_) async => _makeParty(entryGroups: [groupA, groupB]),
      );
      when(
        () => mockPartyRepo.updateParty(any()),
      ).thenAnswer((_) async => _makeParty());

      final (:container, :ctx) = await _buildScope(
        tester,
        mockRepo: mockPartyRepo,
        mockRouter: mockRouter,
      );
      final sub = container.listen(partyDetailProvider('party-1'), (_, _) {});
      addTearDown(sub.close);
      await tester.pump(const Duration(milliseconds: 100));

      await container
          .read(partyDetailCoordinatorProvider)
          .removePartyEntryGroup('party-1', 'g-A', ctx);

      final captured = verify(
        () => mockPartyRepo.updateParty(captureAny()),
      ).captured;
      final updatedParty = captured.first as Party;
      expect(updatedParty.entryGroups, hasLength(1));
      expect(updatedParty.entryGroups!.first.id, 'g-B');
    });
  });

  // Fix #1733: tap 경로 regression — 입장 조건 탭 시 toast가 아닌 화면 전환이 발생해야 함
  group('PartyDetailCoordinator.openEntryGroupManagement', () {
    testWidgets('pushes PartyEntryGroupManagementScreen — not a toast', (
      tester,
    ) async {
      final mockObserver = MockNavigatorObserver();

      when(() => mockPartyRepo.getPartyById('party-1')).thenAnswer(
        (_) async => _makeParty(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            goRouterProvider.overrideWithValue(mockRouter),
          ],
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            locale: const Locale('ko'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final coordinator = ProviderScope.containerOf(
                  context,
                ).read(partyDetailCoordinatorProvider);
                return ElevatedButton(
                  onPressed: () =>
                      coordinator.openEntryGroupManagement(context, 'party-1'),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Regression: 이전에는 toast/no-op이었으므로 실제 route push가 발생했는지 확인
      verify(() => mockObserver.didPush(any(), any()));
    });
  });

  group('PartyDetailCoordinator.updatePartyEntryGroup', () {
    testWidgets('replaces the matching group and calls updateParty', (
      tester,
    ) async {
      final now = DateTime.now();
      final original = PartyEntryGroup(
        id: 'g-1',
        partyId: 'party-1',
        createdAt: now,
        updatedAt: now,
      );
      final updated = original.copyWith(gender: 'female');

      when(() => mockPartyRepo.getPartyById('party-1')).thenAnswer(
        (_) async => _makeParty(entryGroups: [original]),
      );
      when(
        () => mockPartyRepo.updateParty(any()),
      ).thenAnswer((_) async => _makeParty());

      final (:container, :ctx) = await _buildScope(
        tester,
        mockRepo: mockPartyRepo,
        mockRouter: mockRouter,
      );
      final sub = container.listen(partyDetailProvider('party-1'), (_, _) {});
      addTearDown(sub.close);
      await tester.pump(const Duration(milliseconds: 100));

      await container
          .read(partyDetailCoordinatorProvider)
          .updatePartyEntryGroup('party-1', updated, ctx);

      final captured = verify(
        () => mockPartyRepo.updateParty(captureAny()),
      ).captured;
      final updatedParty = captured.first as Party;
      expect(updatedParty.entryGroups, hasLength(1));
      expect(updatedParty.entryGroups!.first.gender, 'female');
    });
  });
}
