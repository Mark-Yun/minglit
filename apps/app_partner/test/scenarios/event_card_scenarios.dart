import 'package:app_partner/src/features/party/event/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class EventCardScenarios {
  static final _baseTime = DateTime(2026, 4, 15, 19);

  static Event get _baseEvent => Event(
    id: 'e1',
    partyId: 'p1',
    startTime: _baseTime,
    endTime: _baseTime.add(const Duration(hours: 2)),
    createdAt: _baseTime,
    updatedAt: _baseTime,
    title: '금요 파티',
    currentParticipants: 12,
  );

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'event_card_scheduled',
      page: EventCard(event: _baseEvent, onTap: () {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'event_card_full',
      page: EventCard(
        event: _baseEvent.copyWith(currentParticipants: 20),
        onTap: () {},
      ),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'event_card_no_title',
      page: EventCard(event: _baseEvent.copyWith(title: null), onTap: () {}),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'event_card_scheduled_dark',
      page: EventCard(event: _baseEvent, onTap: () {}),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'event_card_full_dark',
      page: EventCard(
        event: _baseEvent.copyWith(currentParticipants: 20),
        onTap: () {},
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'event_card_no_title_dark',
      page: EventCard(event: _baseEvent.copyWith(title: null), onTap: () {}),
      brightness: Brightness.dark,
      isComponent: true,
    ),
  ];
}
