import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/logic/purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockEventRepository mockEventRepository;
  late MockUser mockUser;

  final baseEvent = Event(
    id: 'event1',
    partyId: 'party1',
    startTime: DateTime(2026, 6, 1, 19),
    endTime: DateTime(2026, 6, 1, 21),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    title: 'Test Event',
  );

  final baseApplication = EventApplication(
    id: 'app1',
    eventId: 'event1',
    ticketId: 'ticket1',
    userId: 'user1',
    status: 'paid',
    paymentAmount: 50000,
    paymentId: 'imp_test123',
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
    paidAt: DateTime(2026, 5, 1),
    event: baseEvent,
    ticket: Ticket(
      id: 'ticket1',
      name: 'General',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  );

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
  });

  Widget createTestWidget(EventApplication application) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => mockUser),
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        purchaseHistoryControllerProvider.overrideWith(
          () => PurchaseHistoryController(),
        ),
        purchaseHistoryDetailProvider('app1').overrideWith(
          (ref) async => application,
        ),
      ],
      child: const MaterialApp(
        home: PurchaseHistoryDetailPage(applicationId: 'app1'),
      ),
    );
  }

  // Fix #2345: regression — successful cancel must re-fetch purchase history list.
  // Uses an external ProviderContainer listener to simulate PurchaseHistoryPage
  // watching purchaseHistoryControllerProvider, then verifies a post-cancel
  // re-fetch happens — which only occurs if ref.invalidate is called in onSuccess.
  group('PurchaseHistoryDetailPage cancel refresh — Fix #2345', () {
    testWidgets(
      'successful cancel triggers purchaseHistoryController re-fetch',
      (tester) async {
        var historyFetchCount = 0;
        final now = DateTime.now();

        final futureEvent = Event(
          id: 'event1',
          partyId: 'party1',
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          createdAt: now,
          updatedAt: now,
          title: 'Free Cancel Event',
        );

        final freeApp = EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'approved',
          paymentAmount: 0,
          paymentId: null,
          refundStatus: 'none',
          createdAt: now,
          updatedAt: now,
          event: futureEvent,
        );

        when(
          () => mockEventRepository.getMyPurchaseHistory('user1'),
        ).thenAnswer((_) async {
          historyFetchCount++;
          return [freeApp];
        });
        when(
          () => mockEventRepository.cancelOrder(
            eventId: any(named: 'eventId'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer(
          (_) async => const CancelOrderResult(type: 'cancelled'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => mockUser),
              eventRepositoryProvider.overrideWithValue(mockEventRepository),
              // Override detail provider so it returns freeApp directly,
              // bypassing getPurchaseHistoryDetailById. The external listener
              // below independently detects the post-cancel re-fetch.
              purchaseHistoryDetailProvider('app1').overrideWith(
                (ref) async => freeApp,
              ),
            ],
            child: const MaterialApp(
              home: PurchaseHistoryDetailPage(applicationId: 'app1'),
            ),
          ),
        );

        // Attach a listener via ProviderScope.containerOf to simulate
        // PurchaseHistoryPage keeping the list controller alive across
        // the navigation pop — mirrors the real app's base-route watcher.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PurchaseHistoryDetailPage)),
        );
        final sub = container.listen(
          purchaseHistoryControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await tester.pumpAndSettle();
        final fetchCountAfterLoad = historyFetchCount;
        expect(fetchCountAfterLoad, greaterThan(0));

        // Cancel button must be enabled (approved free ticket, future event).
        // The button is inside a SingleChildScrollView — scroll it into view.
        final cancelBtn = find.widgetWithText(ElevatedButton, '예매 취소');
        expect(tester.widget<ElevatedButton>(cancelBtn).onPressed, isNotNull);
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Confirm cancel in dialog
        await tester.tap(find.text('취소하기'));
        await tester.pumpAndSettle();

        // Removing ref.invalidate from onSuccess (the Fix #2345 change) must
        // make this assertion fail.
        expect(historyFetchCount, greaterThan(fetchCountAfterLoad));
      },
    );
  });

  group('PurchaseHistoryDetailPage — #2095', () {
    testWidgets('shows event title and payment info', (tester) async {
      await tester.pumpWidget(createTestWidget(baseApplication));
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('50,000원'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
    });

    testWidgets('shows refund info card when refund completed', (tester) async {
      final refundedApp = baseApplication.copyWith(
        refundStatus: 'completed',
      );
      await tester.pumpWidget(createTestWidget(refundedApp));
      await tester.pump();
      await tester.pump();

      expect(find.text('환불 정보'), findsOneWidget);
      expect(find.text('결제 정보'), findsNothing);
    });

    testWidgets('shows payment info card when not refunded', (tester) async {
      await tester.pumpWidget(createTestWidget(baseApplication));
      await tester.pump();
      await tester.pump();

      expect(find.text('결제 정보'), findsOneWidget);
      expect(find.text('환불 정보'), findsNothing);
    });

    testWidgets('cancel button is disabled when canCancel is false', (
      tester,
    ) async {
      final pastApp = baseApplication.copyWith(
        event: baseEvent.copyWith(
          startTime: DateTime(2020, 1, 1),
          endTime: DateTime(2020, 1, 1, 2),
        ),
      );
      await tester.pumpWidget(createTestWidget(pastApp));
      await tester.pump();
      await tester.pump();

      final cancelBtn = find.widgetWithText(ElevatedButton, '예매 취소');
      expect(cancelBtn, findsOneWidget);
      final btn = tester.widget<ElevatedButton>(cancelBtn);
      expect(btn.onPressed, isNull);
    });

    testWidgets('shows null state message when application is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
            purchaseHistoryControllerProvider.overrideWith(
              () => PurchaseHistoryController(),
            ),
            purchaseHistoryDetailProvider('app1').overrideWith(
              (ref) async => null,
            ),
          ],
          child: const MaterialApp(
            home: PurchaseHistoryDetailPage(applicationId: 'app1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('구매 내역을 찾을 수 없습니다.'), findsOneWidget);
    });
  });
}
