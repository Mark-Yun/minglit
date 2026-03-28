import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockGoRouter mockRouter;
  late EventCoordinator coordinator;

  setUp(() {
    mockRouter = MockGoRouter();
    coordinator = EventCoordinator(mockRouter);

    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  group('EventCoordinator', () {
    test('pushEventDetail pushes correct route', () {
      coordinator.pushEventDetail('event-123');

      verify(
        () => mockRouter.push('/events/event-123'),
      ).called(1);
    });

    test('pushPartnerDetail pushes correct route', () {
      coordinator.pushPartnerDetail('partner-456');

      verify(
        () => mockRouter.push('/partners/partner-456'),
      ).called(1);
    });

    test('goToEventDetail navigates to correct route', () {
      coordinator.goToEventDetail('event-789');

      verify(
        () => mockRouter.go('/events/event-789'),
      ).called(1);
    });

    test('pushEventCuration pushes curation route', () {
      coordinator.pushEventCuration(EventFeedType.newArrivals);

      verify(
        () => mockRouter.push('/curation'),
      ).called(1);
    });

    test('pushEventCuration with non-default type includes query param', () {
      coordinator.pushEventCuration(EventFeedType.nearest);

      verify(
        () => mockRouter.push(any(that: contains('/curation'))),
      ).called(1);
    });

    test('goToApplicationWizard pushes apply route', () {
      coordinator.goToApplicationWizard('event-abc');

      verify(
        () => mockRouter.push('/events/event-abc/apply'),
      ).called(1);
    });

    test('goToApplicationWizard with ticketId includes query param', () {
      coordinator.goToApplicationWizard('event-abc', ticketId: 'ticket-1');

      verify(
        () => mockRouter.push('/events/event-abc/apply?ticket-id=ticket-1'),
      ).called(1);
    });

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
                    onPressed: () =>
                        coordinator.showTicketSelection(context, event),
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
                    onPressed: () =>
                        coordinator.showTicketSelection(context, event),
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
