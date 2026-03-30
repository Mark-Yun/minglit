import 'package:app_user/src/features/ticket/logic/ticket_coordinator.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/test_utils.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('TicketCoordinator', () {
    test('creates from provider with GoRouter', () {
      final container = createContainer(
        overrides: [
          goRouterProvider.overrideWithValue(mockRouter),
        ],
      );

      final coordinator = container.read(ticketCoordinatorProvider);

      expect(coordinator, isA<TicketCoordinator>());
    });

    test('pushEventDetail calls router.push with event ID', () {
      TicketCoordinator(mockRouter).pushEventDetail('event_456');

      verify(() => mockRouter.push(any(that: contains('event_456')))).called(1);
    });

    // Fix #634: showTicketSelection 테스트 — event_coordinator에서 이동
    group('showTicketSelection', () {
      late MockEventRepository mockEventRepository;
      late MockUserRepository mockUserRepository;

      setUp(() {
        mockEventRepository = MockEventRepository();
        mockUserRepository = MockUserRepository();

        when(
          () => mockEventRepository.getTicketBalanceStatus(any()),
        ).thenAnswer((_) async => <String, bool>{});
        when(
          () => mockUserRepository.getUserProfile(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockUserRepository.getApprovedVerificationIds(any()),
        ).thenAnswer((_) async => <String>[]);
      });

      testWidgets('shows TicketSelectionSheet as bottom sheet', (
        tester,
      ) async {
        final coordinator = TicketCoordinator(mockRouter);
        final now = DateTime(2026, 4);
        final event = Event(
          id: 'event-1',
          partyId: 'party-1',
          title: 'Test Event',
          startTime: now,
          endTime: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              eventRepositoryProvider.overrideWithValue(mockEventRepository),
              currentUserProvider.overrideWith((_) => null),
              userRepositoryProvider.overrideWithValue(mockUserRepository),
            ],
            child: MaterialApp(
              theme: MinglitTheme.materialTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => coordinator.showTicketSelection(
                      context,
                      event,
                      onTicketSelected: (_, _) {},
                    ),
                    child: const Text('Show'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byType(TicketSelectionSheet), findsOneWidget);
      });

      testWidgets('dismissing bottom sheet does not navigate', (
        tester,
      ) async {
        final coordinator = TicketCoordinator(mockRouter);
        final now = DateTime(2026, 4);
        final event = Event(
          id: 'event-2',
          partyId: 'party-2',
          title: 'Test Event 2',
          startTime: now,
          endTime: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              eventRepositoryProvider.overrideWithValue(mockEventRepository),
              currentUserProvider.overrideWith((_) => null),
              userRepositoryProvider.overrideWithValue(mockUserRepository),
            ],
            child: MaterialApp(
              theme: MinglitTheme.materialTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => coordinator.showTicketSelection(
                      context,
                      event,
                      onTicketSelected: (_, _) {},
                    ),
                    child: const Text('Show'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();
        expect(find.byType(TicketSelectionSheet), findsOneWidget);

        // Dismiss by tapping the barrier
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        expect(find.byType(TicketSelectionSheet), findsNothing);
        verifyNever(() => mockRouter.push(any()));
      });
    });
  });
}
