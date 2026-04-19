import 'package:app_partner/src/features/home/widgets/upcoming_events_card.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class UpcomingEventsScenarios {
  static final _baseTime = DateTime(2026, 4, 15, 19);

  static Event _makeEvent(String id, String title, int daysFromBase) {
    final start = _baseTime.add(Duration(days: daysFromBase));
    return Event(
      id: id,
      partyId: 'p1',
      startTime: start,
      endTime: start.add(const Duration(hours: 2)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      title: title,
    );
  }

  static List<Event> get _threeEvents => [
    _makeEvent('e1', '금요 파티', 1),
    _makeEvent('e2', '토요 모임', 2),
    _makeEvent('e3', '일요 브런치', 3),
  ];

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'upcoming_events_empty',
      page: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'upcoming_events_with_data',
      page: UpcomingEventsCard(events: _threeEvents, onEventTap: (_) {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'upcoming_events_empty_dark',
      page: UpcomingEventsCard(events: const [], onEventTap: (_) {}),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'upcoming_events_with_data_dark',
      page: UpcomingEventsCard(events: _threeEvents, onEventTap: (_) {}),
      brightness: Brightness.dark,
      isComponent: true,
    ),
  ];
}
