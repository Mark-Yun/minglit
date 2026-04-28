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

void main() {
  group('PartnerHomePage', () {
    testWidgets('shows location guide banner and forwards tap', (tester) async {
      // Fix #1269: P-S06 장소 가이드 배너가 홈에서 사라진 회귀를 막는다.
      final coordinator = _MockPartnerHomeCoordinator();
      when(coordinator.pushNotificationCenter).thenReturn(null);
      when(coordinator.pushLocationGuide).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (_) async => const Partner(id: 'partner_1', name: '테스트 파트너'),
            ),
            partnerHomeCoordinatorProvider.overrideWithValue(coordinator),
            partnerDashboardControllerProvider.overrideWith(
              _LoadedDashboardController.new,
            ),
            notificationListProvider.overrideWith(_EmptyNotificationList.new),
          ],
          child: const MaterialApp(home: PartnerHomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('장소 가이드'), findsOneWidget);

      await tester.tap(find.text('장소 가이드'));
      await tester.pumpAndSettle();

      verify(coordinator.pushLocationGuide).called(1);
    });

    testWidgets(
      'Fix #1950: WeeklyStatsRow is not rendered on PartnerHomePage',
      (tester) async {
        // Regression guard: WeeklyStatsRow was showing hardcoded ₩0 / 0%
        // because the backend API is not yet wired. It must stay hidden until
        // the API is implemented and real data is available.
        final coordinator = _MockPartnerHomeCoordinator();
        when(coordinator.pushNotificationCenter).thenReturn(null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentPartnerInfoProvider.overrideWith(
                (_) async => const Partner(id: 'partner_1', name: '테스트 파트너'),
              ),
              partnerHomeCoordinatorProvider.overrideWithValue(coordinator),
              partnerDashboardControllerProvider.overrideWith(
                _LoadedDashboardController.new,
              ),
              notificationListProvider.overrideWith(_EmptyNotificationList.new),
            ],
            child: const MaterialApp(home: PartnerHomePage()),
          ),
        );
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
