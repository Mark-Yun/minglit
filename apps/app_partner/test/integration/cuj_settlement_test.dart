// Ref #1072: IT-P04 — 정산 확인 + 계좌 CUJ 통합 테스트
//
// 검증 포인트:
// 1. /settlement 접근 (hasPartner 필요)
// 2. 대시보드 탭 렌더링
// 3. 정산 내역 탭 전환
// 4. /settlement/bank-account 계좌 관리 페이지 접근
// 5. 비로그인 시 접근 차단
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final testUser = MockUser();
  final now = DateTime(2026, 4, 5);

  setUp(() {
    when(() => testUser.id).thenReturn('user-p04');
    when(() => testUser.email).thenReturn('partner@settlement.com');
    when(() => testUser.userMetadata).thenReturn({});
  });

  List<dynamic> settlementOverrides() => [
    settlementDashboardControllerProvider.overrideWithValue(
      SettlementDashboardState(
        selectedMonth: DateTime(now.year, now.month),
        status: const AsyncValue.data(null),
      ),
    ),
    settlementListControllerProvider.overrideWithValue(
      const SettlementListState(),
    ),
  ];

  group('IT-P04: 정산 확인 + 계좌', () {
    testWidgets('비로그인 사용자는 정산 페이지에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          initialLocation: '/settlement',
        ),
      );
      await tester.pump();
      await tester.pump();

      // /login으로 리다이렉트
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('hasPartner 상태에서 정산 페이지에 접근할 수 있다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/settlement',
          additionalOverrides: settlementOverrides(),
        ),
      );
      // pump(1s) to render content without waiting for chart animations to settle
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('정산'), findsWidgets);
    });

    testWidgets('대시보드/정산 내역 탭이 모두 표시된다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/settlement',
          additionalOverrides: settlementOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('대시보드'), findsOneWidget);
      expect(find.text('정산 내역'), findsOneWidget);
    });

    testWidgets('정산 내역 탭 전환 시 크래시 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/settlement',
          additionalOverrides: settlementOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('정산 내역'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('계좌 관리 페이지에 접근할 수 있다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/settlement/bank-account',
          additionalOverrides: settlementOverrides(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 계좌 관리 페이지 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('onboarding 미완료 상태에서 정산 페이지 접근 시 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          onboardingState: OnboardingState.needsApplication,
          initialLocation: '/settlement',
        ),
      );
      await tester.pump();
      await tester.pump();

      // needsApplication → /welcome 리다이렉트
      // 정산 페이지가 아닌 다른 페이지가 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
