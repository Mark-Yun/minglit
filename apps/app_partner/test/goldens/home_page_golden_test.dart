@Tags(['golden'])
library;

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('PartnerHomePage golden', () {
    final baseTime = DateTime(2026, 5, 10, 19);
    final mockCoordinator = MockPartnerHomeCoordinator();

    testWidgets('empty dashboard', (tester) async {
      await expectPageGolden(
        tester,
        page: const PartnerHomePage(),
        goldenFileName: 'goldens/partner_home_page_empty.png',
        overrides: [
          currentPartnerInfoProvider.overrideWith(
            (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
          ),
          partnerHomeCoordinatorProvider.overrideWithValue(mockCoordinator),
          partnerDashboardControllerProvider.overrideWith(
            _EmptyDashboardController.new,
          ),
        ],
      );
    });

    testWidgets('with data', (tester) async {
      final events = List.generate(
        2,
        (i) => Event(
          id: 'e$i',
          partyId: 'p1',
          startTime: baseTime.add(Duration(days: i + 1)),
          endTime: baseTime.add(Duration(days: i + 1, hours: 2)),
          createdAt: baseTime,
          updatedAt: baseTime,
          title: '이벤트 ${i + 1}',
          currentParticipants: (i + 1) * 5,
        ),
      );
      final parties = [
        Party(
          id: 'party1',
          partnerId: 'p1',
          title: '금요 밍글 파티',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ];

      await expectPageGolden(
        tester,
        page: const PartnerHomePage(),
        goldenFileName: 'goldens/partner_home_page_with_data.png',
        overrides: [
          currentPartnerInfoProvider.overrideWith(
            (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
          ),
          partnerHomeCoordinatorProvider.overrideWithValue(mockCoordinator),
          partnerDashboardControllerProvider.overrideWith(
            () => _LoadedDashboardController(
              pendingCount: 3,
              upcoming: events,
              closingSoon: [events.first],
              active: parties,
            ),
          ),
        ],
      );
    });

    testWidgets('empty dashboard (dark)', (tester) async {
      await expectPageGolden(
        tester,
        page: const PartnerHomePage(),
        goldenFileName: 'goldens/partner_home_page_empty_dark.png',
        overrides: [
          currentPartnerInfoProvider.overrideWith(
            (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
          ),
          partnerHomeCoordinatorProvider.overrideWithValue(mockCoordinator),
          partnerDashboardControllerProvider.overrideWith(
            _EmptyDashboardController.new,
          ),
        ],
        brightness: Brightness.dark,
      );
    });

    testWidgets('with data (dark)', (tester) async {
      final events = List.generate(
        2,
        (i) => Event(
          id: 'e$i',
          partyId: 'p1',
          startTime: baseTime.add(Duration(days: i + 1)),
          endTime: baseTime.add(Duration(days: i + 1, hours: 2)),
          createdAt: baseTime,
          updatedAt: baseTime,
          title: '이벤트 ${i + 1}',
          currentParticipants: (i + 1) * 5,
        ),
      );
      final parties = [
        Party(
          id: 'party1',
          partnerId: 'p1',
          title: '금요 밍글 파티',
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ];

      await expectPageGolden(
        tester,
        page: const PartnerHomePage(),
        goldenFileName: 'goldens/partner_home_page_with_data_dark.png',
        overrides: [
          currentPartnerInfoProvider.overrideWith(
            (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
          ),
          partnerHomeCoordinatorProvider.overrideWithValue(mockCoordinator),
          partnerDashboardControllerProvider.overrideWith(
            () => _LoadedDashboardController(
              pendingCount: 3,
              upcoming: events,
              closingSoon: [events.first],
              active: parties,
            ),
          ),
        ],
        brightness: Brightness.dark,
      );
    });
  });
}

class _EmptyDashboardController extends PartnerDashboardController {
  @override
  PartnerDashboardState build() => const PartnerDashboardState(
    status: AsyncValue.data(null),
  );
}

class _LoadedDashboardController extends PartnerDashboardController {
  _LoadedDashboardController({
    required this.pendingCount,
    required this.upcoming,
    required this.closingSoon,
    required this.active,
  });

  final int pendingCount;
  final List<Event> upcoming;
  final List<Event> closingSoon;
  final List<Party> active;

  @override
  PartnerDashboardState build() => PartnerDashboardState(
    status: const AsyncValue.data(null),
    pendingReviewCount: pendingCount,
    upcomingEvents: upcoming,
    closingSoonEvents: closingSoon,
    activeParties: active,
  );
}
