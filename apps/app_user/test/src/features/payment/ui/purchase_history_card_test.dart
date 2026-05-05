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

  group('PurchaseHistoryCard — Fix #579 구매일 표시 회귀 테스트', () {
    testWidgets('displays paidAt date when available', (tester) async {
      final paidDate = DateTime(2026, 3, 15);
      final createdDate = DateTime(2026, 3, 10);

      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          createdAt: createdDate,
          updatedAt: createdDate,
          paidAt: paidDate,
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2026, 4, 1, 19),
            endTime: DateTime(2026, 4, 1, 21),
            createdAt: createdDate,
            updatedAt: createdDate,
            title: 'Paid Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Standard Ticket',
            createdAt: createdDate,
            updatedAt: createdDate,
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

      // paidAt 날짜(2026.03.15)가 표시되어야 함
      expect(find.text('2026.03.15'), findsOneWidget);
      // createdAt 날짜(2026.03.10)는 표시되지 않아야 함
      expect(find.text('2026.03.10'), findsNothing);
    });

    testWidgets('falls back to createdAt when paidAt is null', (tester) async {
      final createdDate = DateTime(2026, 3, 10);

      final mockHistory = [
        EventApplication(
          id: 'app2',
          eventId: 'event2',
          ticketId: 'ticket2',
          userId: 'user1',
          status: 'paid',
          createdAt: createdDate,
          updatedAt: createdDate,
          event: Event(
            id: 'event2',
            partyId: 'party2',
            startTime: DateTime(2026, 4, 5, 19),
            endTime: DateTime(2026, 4, 5, 21),
            createdAt: createdDate,
            updatedAt: createdDate,
            title: 'Free Event',
          ),
          ticket: Ticket(
            id: 'ticket2',
            name: 'Free Ticket',
            createdAt: createdDate,
            updatedAt: createdDate,
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

      // paidAt가 null이면 createdAt(2026.03.10)이 표시되어야 함
      expect(find.text('2026.03.10'), findsOneWidget);
    });
  });

  group('PurchaseHistoryCard — Fix #2076 무료 티켓 영수증 버튼 회귀 테스트', () {
    testWidgets('무료 티켓 영수증 버튼 탭 시 신청 확인서 다이얼로그가 표시된다', (
      tester,
    ) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'approved',
          paymentAmount: 0,
          createdAt: DateTime(2026, 4),
          updatedAt: DateTime(2026, 4),
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2026, 5, 1, 19),
            endTime: DateTime(2026, 5, 1, 21),
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
            title: '무료 소셜 이벤트',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: '무료 티켓',
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
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

      // 영수증 버튼이 무료 티켓에도 표시된다
      expect(find.text('영수증'), findsOneWidget);

      // 탭하면 신청 확인서 다이얼로그가 열린다
      await tester.tap(find.text('영수증'));
      await tester.pumpAndSettle();

      expect(find.text('신청 확인서'), findsOneWidget);
      // The card also shows "0원" for price — dialog adds another instance.
      expect(find.text('0원'), findsAtLeast(1));
      expect(find.text('무료 티켓은 결제 영수증이 발행되지 않습니다.'), findsOneWidget);
    });
  });

  group('PurchaseHistoryCard — Fix #1236 버튼 위계 회귀 테스트', () {
    testWidgets('영수증/문의하기 버튼은 TextButton (OutlinedButton 아님)', (
      tester,
    ) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          paymentId: 'pay_abc123',
          createdAt: DateTime(2026, 4),
          updatedAt: DateTime(2026, 4),
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2026, 5, 1, 19),
            endTime: DateTime(2026, 5, 1, 21),
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
            title: 'Test Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Standard Ticket',
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
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

      // Fix #1236: 보조 버튼은 TextButton — 브랜드 보라 아웃라인 제거
      expect(find.text('영수증'), findsOneWidget);
      expect(find.text('문의하기'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('PurchaseHistoryCard — Fix #1820 영수증 버튼/버튼 정렬 회귀 테스트', () {
    testWidgets('paymentId가 null이어도 영수증 버튼이 표시된다 (Fix #2076)', (
      tester,
    ) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          createdAt: DateTime(2026, 4),
          updatedAt: DateTime(2026, 4),
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2026, 5, 1, 19),
            endTime: DateTime(2026, 5, 1, 21),
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
            title: 'Free Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Free Ticket',
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
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

      // Fix #2076: 무료 티켓도 영수증 버튼 표시 — CUJ-U03 spec
      expect(find.text('영수증'), findsOneWidget);
      expect(find.text('문의하기'), findsOneWidget);
    });

    testWidgets('paymentId가 있으면 영수증 버튼이 표시된다', (tester) async {
      final mockHistory = [
        EventApplication(
          id: 'app1',
          eventId: 'event1',
          ticketId: 'ticket1',
          userId: 'user1',
          status: 'paid',
          paymentId: 'imp_1234567890',
          createdAt: DateTime(2026, 4),
          updatedAt: DateTime(2026, 4),
          event: Event(
            id: 'event1',
            partyId: 'party1',
            startTime: DateTime(2026, 5, 1, 19),
            endTime: DateTime(2026, 5, 1, 21),
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
            title: 'Paid Event',
          ),
          ticket: Ticket(
            id: 'ticket1',
            name: 'Paid Ticket',
            createdAt: DateTime(2026, 4),
            updatedAt: DateTime(2026, 4),
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

      // Fix #1820: paymentId 있으면 영수증 버튼 표시
      expect(find.text('영수증'), findsOneWidget);
      expect(find.text('문의하기'), findsOneWidget);
    });
  });
}
