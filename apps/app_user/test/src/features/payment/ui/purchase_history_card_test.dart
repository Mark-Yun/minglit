import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
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

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
  });

  Widget createTestWidget(List<dynamic> overrides) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(
        home: PurchaseHistoryPage(),
      ),
    );
  }

  group('PurchaseHistoryCard — Fix #270 회귀 테스트', () {
    testWidgets('renders card without crash when paymentAmount is null', (
      tester,
    ) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2024, 1, 10, 19),
            endTime: DateTime(2024, 1, 10, 21),
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
            title: 'Free Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Free Ticket',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ),
      ];

      when(
        () => mockEventRepository.getMyPurchaseHistory('user1'),
      ).thenAnswer((_) async => mockHistory);

      await tester.pumpWidget(
        createTestWidget([
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ]),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      // 크래시 없이 렌더링 되어야 함
      expect(find.text('Free Event'), findsOneWidget);
      expect(find.text('Free Ticket'), findsOneWidget);
    });
  });
}
