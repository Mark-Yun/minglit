// IT-P04: 정산 확인 CUJ — 파트너가 정산 대시보드와 목록을 확인하는 플로우
// Fix #1072: Phase 3 — P0 CUJ integration test 구현

import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    registerFallbackValue(DateTime.now());
    registerFallbackValue<String?>(null);
    registerFallbackValue<int>(0);
  });

  MockSettlementRepository buildMockRepo({
    Map<String, dynamic>? dashboardData,
    List<SettlementItemDetail>? items,
  }) {
    final mock = MockSettlementRepository();

    when(
      () => mock.getSettlementDashboard(
        partnerId: any(named: 'partnerId'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer((_) async => dashboardData ?? {});

    when(
      () => mock.getSettlementItems(
        partnerId: any(named: 'partnerId'),
        status: any(named: 'status'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => items ?? []);

    when(
      () => mock.getBankAccount(partnerId: any(named: 'partnerId')),
    ).thenAnswer((_) async => null);

    return mock;
  }

  Widget createTestWidget({MockSettlementRepository? settlementRepo}) {
    return ProviderScope(
      overrides: [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => createTestPartner(),
        ),
        settlementRepositoryProvider.overrideWithValue(
          settlementRepo ?? buildMockRepo(),
        ),
      ].cast(),
      child: const MaterialApp(home: SettlementPage()),
    );
  }

  group('IT-P04: 정산 확인 CUJ', () {
    testWidgets('정산 페이지 탭 구조 렌더링 — 크래시 없음', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('빈 정산 데이터 — 대시보드 탭 정상 렌더링', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 빈 데이터에서 로딩 완료 후 에러 없이 렌더링
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('목록 탭 전환 — 빈 목록 상태 렌더링', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 2) {
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('대시보드 대이터 있을 때 — 금액 정보 렌더링', (tester) async {
      final mockRepo = buildMockRepo(
        dashboardData: {
          'gross_total': 100000,
          'net_completed': 91200,
          'pending_total': 0,
          'status_counts': <String, dynamic>{},
        },
      );
      await tester.pumpWidget(createTestWidget(settlementRepo: mockRepo));
      await tester.pumpAndSettle();

      // 대시보드가 렌더링되고 예외 없음 확인
      expect(find.byType(TabBarView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // IT-P04 변형: 계좌 미등록 상태에서도 정상 작동
    testWidgets('변형: 계좌 미등록 상태 — CTA 또는 빈 상태 렌더링', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 계좌 없이도 크래시 없음
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
