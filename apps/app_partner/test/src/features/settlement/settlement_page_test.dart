// Fix #1568: 정산 탭 AppBar에 계좌 관리 진입 버튼 추가
//
// Regression guard:
// T1: SETTLEMENT_EDIT 권한 있는 유저 → 계좌 관리 버튼 표시
// T2: SETTLEMENT_VIEW만 있는 유저 → 계좌 관리 버튼 미표시
// T3: 버튼 탭 → goToBankAccount() 호출

import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

// Fix #1568: @riverpod class-based Notifier는 overrideWithValue 불가 — overrideWith 사용
class _FakeSettlementDashboardController extends SettlementDashboardController {
  @override
  SettlementDashboardState build() => SettlementDashboardState(
    selectedMonth: DateTime(2026, 4),
    status: const AsyncValue.data(null),
  );
}

class _FakeSettlementListController extends SettlementListController {
  @override
  SettlementListState build() => const SettlementListState();
}

Widget _buildApp({
  required List<String> permissions,
  MockGoRouter? mockRouter,
}) {
  final router = mockRouter ?? MockGoRouter();
  when(() => router.push(any())).thenAnswer((_) => Future.value());

  return ProviderScope(
    overrides: [
      currentMemberPermissionsProvider.overrideWith(
        (ref) async => permissions,
      ),
      currentPartnerInfoProvider.overrideWith(
        (ref) async => const Partner(id: 'partner-1', name: 'Test'),
      ),
      settlementDashboardControllerProvider.overrideWith(
        _FakeSettlementDashboardController.new,
      ),
      settlementListControllerProvider.overrideWith(
        _FakeSettlementListController.new,
      ),
      goRouterProvider.overrideWithValue(router),
    ],
    child: const MaterialApp(
      home: SettlementPage(),
    ),
  );
}

void main() {
  group('SettlementPage — Fix #1568: 계좌 관리 버튼 진입', () {
    testWidgets(
      'T1: SETTLEMENT_EDIT 권한 → 계좌 관리 버튼이 AppBar에 표시된다',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(permissions: ['SETTLEMENT_VIEW', 'SETTLEMENT_EDIT']),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('bankAccountButton')),
          findsOneWidget,
          reason: 'SETTLEMENT_EDIT 권한이 있으면 AppBar에 계좌 관리 버튼이 표시돼야 한다',
        );
      },
    );

    testWidgets(
      'T2: SETTLEMENT_VIEW만 있는 경우 → 계좌 관리 버튼이 표시되지 않는다',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(permissions: ['SETTLEMENT_VIEW']),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('bankAccountButton')),
          findsNothing,
          reason: 'SETTLEMENT_EDIT 권한이 없으면 계좌 관리 버튼이 표시되면 안 된다',
        );
      },
    );

    testWidgets(
      'T2b: 권한이 아예 없는 경우 → 계좌 관리 버튼이 표시되지 않는다',
      (tester) async {
        await tester.pumpWidget(_buildApp(permissions: []));
        await tester.pump();

        expect(find.byKey(const Key('bankAccountButton')), findsNothing);
      },
    );

    testWidgets(
      'T3: 계좌 관리 버튼 탭 → goToBankAccount() 호출 (router.push)',
      (tester) async {
        final mockRouter = MockGoRouter();
        when(() => mockRouter.push(any())).thenAnswer((_) => Future.value());

        await tester.pumpWidget(
          _buildApp(
            permissions: ['SETTLEMENT_EDIT'],
            mockRouter: mockRouter,
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('bankAccountButton')));
        await tester.pump();

        verify(
          () => mockRouter.push(const BankAccountRoute().location),
        ).called(1);
      },
    );
  });
}
