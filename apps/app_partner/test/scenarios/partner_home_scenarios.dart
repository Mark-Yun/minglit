import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart'
    show MockPartnerHomeCoordinator;
import 'partner_screenshot_scenario.dart';

class PartnerHomeScenarios {
  static final _baseTime = DateTime(2026, 5, 10, 19);

  static List<Event> _twoEvents() => List.generate(
    2,
    (i) => Event(
      id: 'e$i',
      partyId: 'p1',
      startTime: _baseTime.add(Duration(days: i + 1)),
      endTime: _baseTime.add(Duration(days: i + 1, hours: 2)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      title: '이벤트 ${i + 1}',
      currentParticipants: (i + 1) * 5,
    ),
  );

  static List<Party> get _parties => [
    Party(
      id: 'party1',
      partnerId: 'p1',
      title: '금요 밍글 파티',
      createdAt: _baseTime,
      updatedAt: _baseTime,
    ),
  ];

  static List<dynamic> _emptyOverrides() => [
    currentPartnerInfoProvider.overrideWith(
      (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
    ),
    partnerHomeCoordinatorProvider.overrideWithValue(
      MockPartnerHomeCoordinator(),
    ),
    partnerDashboardControllerProvider.overrideWith(
      _EmptyDashboardController.new,
    ),
  ];

  static List<dynamic> _withDataOverrides() {
    final events = _twoEvents();
    return [
      currentPartnerInfoProvider.overrideWith(
        (_) async => const Partner(id: 'p1', name: '테스트 파트너'),
      ),
      partnerHomeCoordinatorProvider.overrideWithValue(
        MockPartnerHomeCoordinator(),
      ),
      partnerDashboardControllerProvider.overrideWith(
        () => _LoadedDashboardController(
          pendingCount: 3,
          upcoming: events,
          closingSoon: [events.first],
          active: _parties,
        ),
      ),
    ];
  }

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'partner_home_page_empty',
      page: const PartnerHomePage(),
      overrides: _emptyOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'partner_home_page_with_data',
      page: const PartnerHomePage(),
      overrides: _withDataOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'partner_home_page_empty_dark',
      page: const PartnerHomePage(),
      brightness: Brightness.dark,
      overrides: _emptyOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'partner_home_page_with_data_dark',
      page: const PartnerHomePage(),
      brightness: Brightness.dark,
      overrides: _withDataOverrides(),
    ),
  ];
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
