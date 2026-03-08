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

  group('PurchaseHistoryPage', () {
    testWidgets('renders history cards when data is available', (tester) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          paymentAmount: 20000,
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2024, 1, 10, 19),
            endTime: DateTime(2024, 1, 10, 21),
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
            title: 'Test Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Regular Ticket',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
            price: 20000,
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

      // Wait for async load
      await tester.pump(); // Start build
      await tester.pump(); // Finish future
      await tester.pump(); // Render data

      expect(find.text('구매 내역'), findsOneWidget);
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('Regular Ticket'), findsOneWidget);
      expect(find.text('20,000원'), findsOneWidget);
      expect(find.text('결제완료'), findsOneWidget);
    });

    testWidgets('renders empty state when no history', (tester) async {
      when(
        () => mockEventRepository.getMyPurchaseHistory('user1'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget([
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ]),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('구매 내역이 없습니다.'), findsOneWidget);
    });
  });
}
