import 'package:app_partner/src/features/home/widgets/closing_soon_events_card.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class ClosingSoonScenarios {
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

  static List<Event> get _singleEvent => [_makeEvent('e1', '금요 파티', 1)];

  static List<Event> get _multipleEvents => [
    _makeEvent('e1', '금요 파티', 1),
    _makeEvent('e2', '토요 모임', 2),
    _makeEvent('e3', '일요 브런치', 3),
  ];

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'closing_soon_single',
      page: ClosingSoonEventsCard(events: _singleEvent, onEventTap: (_) {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'closing_soon_multiple',
      page: ClosingSoonEventsCard(events: _multipleEvents, onEventTap: (_) {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'closing_soon_single_dark',
      page: ClosingSoonEventsCard(events: _singleEvent, onEventTap: (_) {}),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'closing_soon_multiple_dark',
      page: ClosingSoonEventsCard(
        events: _multipleEvents,
        onEventTap: (_) {},
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
  ];
}
