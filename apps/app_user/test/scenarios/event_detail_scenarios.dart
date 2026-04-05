import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'screenshot_scenario.dart';

class _MockPolicyRepository extends Mock implements PolicyRepository {}

const _eventId = 'event-golden';
final _baseTime = DateTime(2026, 4, 12, 18);
final _fixedNow = DateTime(2026, 4, 1, 10);

final _location = Location(
  id: 'location-1',
  partnerId: 'partner-1',
  name: '밍글릿 라운지',
  address: '서울 강남구 테헤란로 123',
  createdAt: _baseTime,
  updatedAt: _baseTime,
);

const _partner = Partner(
  id: 'partner-1',
  name: '밍글릿 소셜 클럽',
  introduction: '프리미엄 소셜 이벤트를 운영합니다.',
);

final _party = Party(
  id: 'party-1',
  partnerId: 'partner-1',
  title: '봄 시즌 네트워킹 파티',
  createdAt: _baseTime,
  updatedAt: _baseTime,
  location: _location,
  partner: _partner,
  description: const {
    'ops': [
      {'insert': '도심 한가운데에서 열리는 프리미엄 네트워킹 이벤트입니다.\n'},
      {'insert': '드레스 코드: Smart Casual\n'},
    ],
  },
);

final _ticket = Ticket(
  id: 'ticket-1',
  name: '얼리버드',
  price: 39000,
  quantity: 40,
  soldCount: 24,
  createdAt: _baseTime,
  updatedAt: _baseTime,
  targetEntryGroupIds: const ['group-1'],
);

final _event = Event(
  id: _eventId,
  partyId: _party.id,
  title: _party.title,
  startTime: DateTime(2026, 4, 25, 19),
  endTime: DateTime(2026, 4, 25, 23),
  createdAt: _baseTime,
  updatedAt: _baseTime,
  location: _location,
  party: _party,
  tickets: [_ticket],
  entryGroups: const [
    EntryGroup(
      id: 'group-1',
      eventId: _eventId,
      label: '남성 20대 후반',
      gender: 'male',
      birthYearMin: 1992,
      birthYearMax: 1999,
    ),
  ],
);

List<dynamic> _buildOverrides(AdmissionState admissionState) {
  final mockPolicyRepo = _MockPolicyRepository();
  when(() => mockPolicyRepo.getRefundPolicy()).thenAnswer(
    (_) async => {
      'grace_period_hours': 2,
      'cutoff_days': 7,
    },
  );
  return [
    eventDetailControllerProvider(_eventId).overrideWith(
      () => _MockEventDetailController(_event),
    ),
    eventAdmissionControllerProvider(_event).overrideWith(
      () => _MockAdmissionController(admissionState),
    ),
    entryGroupParticipantCountsProvider(_eventId).overrideWith(
      (ref) async => const {'group-1': 24},
    ),
    verificationsByIdsProvider('').overrideWith((_) async => []),
    policyRepositoryProvider.overrideWith((_) => mockPolicyRepo),
    eventDetailNowProvider.overrideWith((_) => () => _fixedNow),
  ];
}

class EventDetailScenarios {
  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'event_detail_open',
      page: const EventDetailPage(eventId: _eventId),
      overrides: _buildOverrides(
        AdmissionState(status: EventAdmissionStatus.eligible),
      ),
    ),
    ScreenshotScenario(
      name: 'event_detail_sold_out',
      page: const EventDetailPage(eventId: _eventId),
      overrides: _buildOverrides(
        AdmissionState(
          status: EventAdmissionStatus.notEligible,
          ineligibleReason: '매진된 이벤트입니다.',
        ),
      ),
    ),
    ScreenshotScenario(
      name: 'event_detail_closed',
      page: const EventDetailPage(eventId: _eventId),
      overrides: _buildOverrides(
        AdmissionState(
          status: EventAdmissionStatus.notEligible,
          ineligibleReason: '신청이 마감된 이벤트입니다.',
        ),
      ),
    ),
  ];
}

class _MockEventDetailController extends EventDetailController {
  _MockEventDetailController(this._event);

  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

class _MockAdmissionController extends EventAdmissionController {
  _MockAdmissionController(this._state);

  final AdmissionState _state;

  @override
  FutureOr<AdmissionState> build(Event event) async => _state;
}
