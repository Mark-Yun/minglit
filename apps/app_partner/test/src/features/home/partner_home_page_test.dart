// Smoke tests for PartnerHomePage v2 (Fix #2219).
//
// v2 is a notification-center feed replacing the old EventActionCard hero.
// These tests verify the new structure and guard against regressions.
import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/home/widgets/weekly_stats_row.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockPartnerHomeCoordinator extends Mock
    implements PartnerHomeCoordinator {}

class _EmptyNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class _LoadedDashboardController extends PartnerDashboardController {
  @override
  PartnerDashboardState build() => const PartnerDashboardState(
    status: AsyncValue.data(null),
    hasAnyEvents: true,
  );
}

Widget _buildPage({PartnerHomeCoordinator? coordinator}) {
  final coord = coordinator ?? _MockPartnerHomeCoordinator();
  when(coord.pushNotificationCenter).thenReturn(null);
  return ProviderScope(
    overrides: [
      currentPartnerInfoProvider.overrideWith(
        (_) async => const Partner(id: 'partner_1', name: '테스트 파트너'),
      ),
      partnerHomeCoordinatorProvider.overrideWithValue(coord),
      partnerDashboardControllerProvider.overrideWith(
        _LoadedDashboardController.new,
      ),
      notificationListProvider.overrideWith(_EmptyNotificationList.new),
    ],
    child: const MaterialApp(home: PartnerHomePage()),
  );
}

void main() {
  group('PartnerHomePage', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets(
      'Fix #1950: WeeklyStatsRow is not rendered on PartnerHomePage',
      (tester) async {
        // Regression guard: WeeklyStatsRow was showing hardcoded ₩0 / 0%
        // because the backend API is not yet wired. It must stay hidden until
        // the API is implemented and real data is available.
        await tester.pumpWidget(_buildPage());
        await tester.pumpAndSettle();

        expect(
          find.byType(WeeklyStatsRow),
          findsNothing,
          reason: 'WeeklyStatsRow must not appear until backend API is wired',
        );
        expect(
          find.text('이번 주 성과'),
          findsNothing,
          reason:
              'Weekly stats header must not appear until backend API is wired',
        );
      },
    );
  });
}
