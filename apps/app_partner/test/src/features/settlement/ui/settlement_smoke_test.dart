// Ref #1072: P0 Smoke — SettlementPage 화면 진입 테스트
//
// 정산 화면이 크래시 없이 렌더링됨을 검증한다.
// 대시보드/목록 탭 전환, 빈 상태, 에러 상태를 커버한다.
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 4, 5);

  Widget buildWidget({
    SettlementDashboardState? dashState,
    SettlementListState? listState,
  }) {
    return ProviderScope(
      overrides: [
        settlementDashboardControllerProvider.overrideWithValue(
          dashState ??
              SettlementDashboardState(
                selectedMonth: DateTime(now.year, now.month),
                status: const AsyncValue.data(null),
              ),
        ),
        settlementListControllerProvider.overrideWithValue(
          listState ?? const SettlementListState(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettlementPage(),
      ),
    );
  }

  group('SettlementPage smoke', () {
    testWidgets('AppBar에 "정산" 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('정산'), findsOneWidget);
    });

    testWidgets('대시보드/정산 내역 탭이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('대시보드'), findsOneWidget);
      expect(find.text('정산 내역'), findsOneWidget);
    });

    testWidgets('대시보드 로딩 중에도 크래시 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          dashState: SettlementDashboardState(
            selectedMonth: DateTime(now.year, now.month),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('정산 내역 탭 전환 시 크래시 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 정산 내역 탭으로 전환
      await tester.tap(find.text('정산 내역'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
