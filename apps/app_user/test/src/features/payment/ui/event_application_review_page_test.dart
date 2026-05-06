import 'package:app_user/src/features/payment/logic/purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/event_application_review_page.dart';
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
    title: 'Review Event',
  );

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
  });

  Widget createTestWidget(EventApplication application) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        purchaseHistoryDetailProvider('app1').overrideWith(
          (ref) async => application,
        ),
      ],
      child: const MaterialApp(
        home: EventApplicationReviewPage(applicationId: 'app1'),
      ),
    );
  }

  EventApplication makeApp(String status) => EventApplication(
        id: 'app1',
        eventId: 'event1',
        ticketId: 'ticket1',
        userId: 'user1',
        status: status,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
        event: baseEvent,
      );

  group('EventApplicationReviewPage — #2095', () {
    testWidgets('shows timeline for paid status', (tester) async {
      await tester.pumpWidget(createTestWidget(makeApp('paid')));
      await tester.pump();
      await tester.pump();

      expect(find.text('심사 타임라인'), findsOneWidget);
      expect(find.text('예매 완료'), findsOneWidget);
      expect(find.text('다시 신청하기'), findsNothing);
    });

    testWidgets('shows 다시 신청하기 when rejected', (tester) async {
      await tester.pumpWidget(createTestWidget(makeApp('rejected')));
      await tester.pump();
      await tester.pump();

      expect(find.text('반려됨'), findsOneWidget);
      expect(find.text('다시 신청하기'), findsOneWidget);
    });

    testWidgets('shows 다시 신청하기 when payment_failed', (tester) async {
      await tester.pumpWidget(createTestWidget(makeApp('payment_failed')));
      await tester.pump();
      await tester.pump();

      expect(find.text('결제 실패'), findsOneWidget);
      expect(find.text('다시 신청하기'), findsOneWidget);
    });

    testWidgets('shows pending_review state with hourglass step', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(makeApp('pending_review')));
      await tester.pump();
      await tester.pump();

      expect(find.text('심사 진행 중'), findsOneWidget);
      expect(find.text('다시 신청하기'), findsNothing);
    });

    testWidgets('shows null state message when application is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
            purchaseHistoryDetailProvider('app1').overrideWith(
              (ref) async => null,
            ),
          ],
          child: const MaterialApp(
            home: EventApplicationReviewPage(applicationId: 'app1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('신청 내역을 찾을 수 없습니다.'), findsOneWidget);
    });
  });
}
