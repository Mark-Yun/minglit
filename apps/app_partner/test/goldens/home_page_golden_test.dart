@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
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

  final baseTime = DateTime(2026, 5, 10, 19);
  final mockCoordinator = MockPartnerHomeCoordinator();

  goldenTest(
    'PartnerHomePage empty dashboard',
    fileName: 'partner_home_page_empty',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty dashboard',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const PartnerHomePage(),
              overrides: [
                currentPartnerInfoProvider.overrideWith(
                  (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
                ),
                partnerHomeCoordinatorProvider
                    .overrideWithValue(mockCoordinator),
                partnerDashboardControllerProvider.overrideWith(
                  _EmptyDashboardController.new,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PartnerHomePage with data',
    fileName: 'partner_home_page_with_data',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
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

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with data',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartnerHomePage(),
                overrides: [
                  currentPartnerInfoProvider.overrideWith(
                    (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
                  ),
                  partnerHomeCoordinatorProvider
                      .overrideWithValue(mockCoordinator),
                  partnerDashboardControllerProvider.overrideWith(
                    () => _LoadedDashboardController(
                      pendingCount: 3,
                      upcoming: events,
                      closingSoon: [events.first],
                      active: parties,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'PartnerHomePage empty dashboard (dark)',
    fileName: 'partner_home_page_empty_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty dashboard (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const PartnerHomePage(),
              brightness: Brightness.dark,
              overrides: [
                currentPartnerInfoProvider.overrideWith(
                  (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
                ),
                partnerHomeCoordinatorProvider
                    .overrideWithValue(mockCoordinator),
                partnerDashboardControllerProvider.overrideWith(
                  _EmptyDashboardController.new,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PartnerHomePage with data (dark)',
    fileName: 'partner_home_page_with_data_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
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

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with data (dark)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartnerHomePage(),
                brightness: Brightness.dark,
                overrides: [
                  currentPartnerInfoProvider.overrideWith(
                    (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
                  ),
                  partnerHomeCoordinatorProvider
                      .overrideWithValue(mockCoordinator),
                  partnerDashboardControllerProvider.overrideWith(
                    () => _LoadedDashboardController(
                      pendingCount: 3,
                      upcoming: events,
                      closingSoon: [events.first],
                      active: parties,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
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
