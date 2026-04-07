// Ref #1072: P0 Smoke — PurchaseHistoryPage 화면 진입 테스트
//
// 구매 내역 화면이 크래시 없이 렌더링됨을 검증한다.
// 로딩/빈 목록/데이터 상태를 모두 커버한다.
import 'dart:async';

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

  late MockEventRepository mockEventRepo;
  late MockUser mockUser;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('test-user-1');
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => mockUser),
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
      ],
      child: const MaterialApp(home: PurchaseHistoryPage()),
    );
  }

  group('PurchaseHistoryPage smoke', () {
    testWidgets('로딩 중에는 인디케이터가 표시된다', (tester) async {
      // Completer를 사용하여 영원히 pending 상태 유지
      final completer = Completer<List<EventApplication>>();
      when(
        () => mockEventRepo.getMyPurchaseHistory(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget());
      await tester.pump(); // trigger build
      await tester.pump(); // trigger loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('데이터 로드 시 AppBar 제목 "구매 내역"이 표시된다', (tester) async {
      when(
        () => mockEventRepo.getMyPurchaseHistory(any()),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('구매 내역'), findsOneWidget);
    });

    testWidgets('구매 내역 있을 때 카드가 렌더링된다', (tester) async {
      final now = DateTime(2026, 4, 5);
      when(
        () => mockEventRepo.getMyPurchaseHistory(any()),
      ).thenAnswer(
        (_) async => [
          EventApplication(
            id: 'app-smoke-1',
            eventId: 'event-smoke-1',
            ticketId: 'ticket-smoke-1',
            userId: 'test-user-1',
            status: 'paid',
            createdAt: now,
            updatedAt: now,
            paymentAmount: 30000,
            event: Event(
              id: 'event-smoke-1',
              partyId: 'party-1',
              startTime: now.add(const Duration(days: 3)),
              endTime: now.add(const Duration(days: 3, hours: 2)),
              createdAt: now,
              updatedAt: now,
              title: '소셜 다이닝',
            ),
            ticket: Ticket(
              id: 'ticket-smoke-1',
              name: '일반',
              createdAt: now,
              updatedAt: now,
              price: 30000,
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('소셜 다이닝'), findsOneWidget);
      expect(find.text('30,000원'), findsOneWidget);
    });
  });
}
