// Fix #1656: PaymentSuccessScreen Android 뒤로가기 앱 이탈 회귀 방지
//
// Navigator.pushReplacement + GoRouter 혼용 시 Android 뒤로가기로 앱이 홈으로 이탈하는
// 버그를 재현하는 테스트. PopScope(canPop: false)와 CloseButton이 onBackToEvent를
// 위임하는지 검증한다.
import 'package:app_user/src/features/event/admission/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 4, 5, 15);

  final testTicket = Ticket(
    id: 'ticket-1',
    name: '일반 티켓',
    price: 0,
    createdAt: now,
    updatedAt: now,
  );

  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '무료 소개팅 파티',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 3)),
    createdAt: now,
    updatedAt: now,
    tickets: [testTicket],
    entryGroups: [],
  );

  Widget buildWidget({
    VoidCallback? onViewTickets,
    VoidCallback? onBackToEvent,
  }) {
    return MaterialApp(
      home: PaymentSuccessScreen(
        event: testEvent,
        ticketId: testTicket.id,
        onViewTickets: onViewTickets ?? () {},
        onBackToEvent: onBackToEvent ?? () {},
      ),
    );
  }

  group('PaymentSuccessScreen (Fix #1656 회귀)', () {
    testWidgets('Android 뒤로가기 시 onBackToEvent 콜백이 호출된다', (tester) async {
      var backCount = 0;
      await tester.pumpWidget(buildWidget(onBackToEvent: () => backCount++));
      await tester.pumpAndSettle();

      // Simulate Android back button
      final dynamic widgetsAppState =
          tester.state(find.byType(WidgetsApp).first);
      // ignore: avoid_dynamic_calls
      await (widgetsAppState as dynamic).didPopRoute();
      await tester.pumpAndSettle();

      expect(backCount, 1);
    });

    testWidgets('CloseButton이 onBackToEvent 콜백을 사용한다 (Navigator.pop 금지)',
        (tester) async {
      var closeCount = 0;
      await tester.pumpWidget(buildWidget(onBackToEvent: () => closeCount++));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(closeCount, 1);
    });

    testWidgets('"이벤트로 돌아가기" 버튼이 onBackToEvent 콜백을 호출한다', (tester) async {
      var backCount = 0;
      await tester.pumpWidget(buildWidget(onBackToEvent: () => backCount++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('이벤트로 돌아가기'));
      await tester.pumpAndSettle();

      expect(backCount, 1);
    });

    testWidgets('"내 티켓 보기" 버튼이 onViewTickets 콜백을 호출한다', (tester) async {
      var ticketsCount = 0;
      await tester.pumpWidget(buildWidget(onViewTickets: () => ticketsCount++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('내 티켓 보기'));
      await tester.pumpAndSettle();

      expect(ticketsCount, 1);
    });

    testWidgets('결제 완료 메시지와 티켓 요약이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('결제가 완료되었습니다! '), findsOneWidget);
      expect(find.text('티켓 요약'), findsOneWidget);
      expect(find.text('무료 소개팅 파티'), findsOneWidget);
      expect(find.text('일반 티켓'), findsOneWidget);
    });
  });
}
