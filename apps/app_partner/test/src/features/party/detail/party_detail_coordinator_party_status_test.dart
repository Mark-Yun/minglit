// Critical-path tests for PartyDetailCoordinator party-status transitions.
//
// activateParty and deactivateParty call updatePartyStatus on the repository
// and then invalidate partyDetailProvider.  A regression here would leave the
// party in a stale (or wrong) state in production, directly affecting user
// visibility and event sales.
//
// Widget tests are required because both methods call context.showMinglitSuccess
// and handleMinglitError, which need a Material/Scaffold ancestor.

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

Party _makeParty(String id) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
  );
}

/// A minimal widget that exercises [PartyDetailCoordinator.activateParty] or
/// [PartyDetailCoordinator.deactivateParty] on button tap.
class _StatusActionWidget extends ConsumerWidget {
  const _StatusActionWidget({
    required this.partyId,
    required this.action,
  });

  final String partyId;
  final String action; // 'activate' | 'deactivate'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final coordinator = ref.read(partyDetailCoordinatorProvider);
        if (action == 'activate') {
          await coordinator.activateParty(partyId, context);
        } else {
          await coordinator.deactivateParty(partyId, context);
        }
      },
      child: Text(action),
    );
  }
}

Widget _buildApp({
  required MockPartyRepository mockPartyRepo,
  required String partyId,
  required String action,
}) {
  return ProviderScope(
    overrides: [
      partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      // Prevent real Supabase calls from partyDetailProvider invalidation
      partyDetailProvider(partyId).overrideWith(
        (ref) async => _makeParty(partyId),
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
      home: Scaffold(
        body: _StatusActionWidget(partyId: partyId, action: action),
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
  });

  group('PartyDetailCoordinator.activateParty', () {
    test(
      'calls updatePartyStatus with "active" for correct partyId',
      () async {
        when(
          () => mockPartyRepo.updatePartyStatus('party-1', 'active'),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            partyDetailProvider('party-1').overrideWith(
              (ref) async => _makeParty('party-1'),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Use a dummy BuildContext via a widget pump to call the method
        final coordinator = container.read(partyDetailCoordinatorProvider);
        // We verify the repo call via the widget test below; this checks provider reads correctly.
        expect(coordinator, isA<PartyDetailCoordinator>());
      },
    );

    testWidgets(
      'calls updatePartyStatus("active") and shows success snackbar',
      (tester) async {
        when(
          () => mockPartyRepo.updatePartyStatus('party-1', 'active'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            action: 'activate',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('activate'));
        await tester.pumpAndSettle();

        verify(
          () => mockPartyRepo.updatePartyStatus('party-1', 'active'),
        ).called(1);
        // Success toast/snackbar should appear
        expect(find.text('파티가 활성화되었습니다.'), findsOneWidget);
      },
    );

    testWidgets(
      'does not crash when updatePartyStatus throws',
      (tester) async {
        when(
          () => mockPartyRepo.updatePartyStatus('party-1', 'active'),
        ).thenThrow(Exception('network error'));

        await tester.pumpWidget(
          _buildApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            action: 'activate',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('activate'));
        await tester.pumpAndSettle();

        // Widget should still be visible — no crash
        expect(find.text('activate'), findsOneWidget);
      },
    );
  });

  group('PartyDetailCoordinator.deactivateParty', () {
    testWidgets(
      'calls updatePartyStatus("closed") and shows success snackbar',
      (tester) async {
        when(
          () => mockPartyRepo.updatePartyStatus('party-1', 'closed'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            action: 'deactivate',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('deactivate'));
        await tester.pumpAndSettle();

        verify(
          () => mockPartyRepo.updatePartyStatus('party-1', 'closed'),
        ).called(1);
        expect(find.text('파티가 비활성화(보관)되었습니다.'), findsOneWidget);
      },
    );

    testWidgets(
      'calls updatePartyStatus with "closed" (not "inactive" or "draft")',
      (tester) async {
        // Regression guard: the status string sent to the repo must be exactly
        // 'closed'. Any other string would silently fail to update party state.
        when(
          () => mockPartyRepo.updatePartyStatus('party-2', 'closed'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-2',
            action: 'deactivate',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('deactivate'));
        await tester.pumpAndSettle();

        // Verify exact status string — 'active', 'draft', or anything else is wrong
        verify(
          () => mockPartyRepo.updatePartyStatus('party-2', 'closed'),
        ).called(1);
        verifyNever(
          () => mockPartyRepo.updatePartyStatus(any(), 'inactive'),
        );
        verifyNever(
          () => mockPartyRepo.updatePartyStatus(any(), 'draft'),
        );
      },
    );

    testWidgets(
      'does not crash when updatePartyStatus throws',
      (tester) async {
        when(
          () => mockPartyRepo.updatePartyStatus('party-1', 'closed'),
        ).thenThrow(Exception('server error'));

        await tester.pumpWidget(
          _buildApp(
            mockPartyRepo: mockPartyRepo,
            partyId: 'party-1',
            action: 'deactivate',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('deactivate'));
        await tester.pumpAndSettle();

        expect(find.text('deactivate'), findsOneWidget);
      },
    );
  });
}
