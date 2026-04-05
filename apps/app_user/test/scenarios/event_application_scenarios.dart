import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../integration/utils/test_mocks.dart';
import 'screenshot_scenario.dart';

const _eventId = 'event-application-golden';
final _baseTime = DateTime(2026, 4, 12, 18);

final _ticket = Ticket(
  id: 'ticket-vip',
  name: 'VIP 입장권',
  price: 59000,
  createdAt: _baseTime,
  updatedAt: _baseTime,
  targetEntryGroupIds: const ['group-1'],
);

final _event = Event(
  id: _eventId,
  partyId: 'party-1',
  title: '봄 시즌 네트워킹 파티',
  startTime: DateTime(2026, 4, 25, 19),
  endTime: DateTime(2026, 4, 25, 23),
  createdAt: _baseTime,
  updatedAt: _baseTime,
  tickets: [_ticket],
  entryGroups: const [
    EntryGroup(
      id: 'group-1',
      eventId: _eventId,
      label: '직장인 전용',
      requiredVerificationIds: ['career-proof'],
    ),
  ],
);

const _verification = Verification(
  id: 'career-proof',
  category: VerificationCategory.career,
  internalName: 'career_proof',
  displayName: '직장 인증',
  description: '소속 회사와 직무를 입력해주세요.',
  formSchema: [
    VerificationFormField(
      type: 'text',
      label: '회사명',
      key: 'company_name',
      placeholder: '예: Minglit',
    ),
    VerificationFormField(
      type: 'text',
      label: '직무',
      key: 'job_title',
      placeholder: '예: Product Manager',
    ),
  ],
);

List<dynamic> _buildOverrides(EventApplicationState state) => [
  eventDetailControllerProvider(_eventId).overrideWith(
    () => _MockEventDetailController(_event),
  ),
  eventApplicationControllerProvider(_event).overrideWith(
    () => _MockApplicationController(state),
  ),
  verificationsByIdsProvider('career-proof').overrideWith(
    (_) async => [_verification],
  ),
];

class EventApplicationScenarios {
  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'event_application_verification_step',
      page: const EventApplicationWizardPage(eventId: _eventId),
      currentUser: createMockUserForTest(),
      overrides: _buildOverrides(
        EventApplicationState(
          step: EventApplicationStep.verification,
          status: EventApplicationStatus.initial,
          selectedTicket: _ticket,
        ),
      ),
    ),
    ScreenshotScenario(
      name: 'event_application_payment_step',
      page: const EventApplicationWizardPage(eventId: _eventId),
      currentUser: createMockUserForTest(),
      overrides: _buildOverrides(
        EventApplicationState(
          step: EventApplicationStep.payment,
          status: EventApplicationStatus.initial,
          selectedTicket: _ticket,
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

class _MockApplicationController extends EventApplicationController {
  _MockApplicationController(this._state);

  final EventApplicationState _state;

  @override
  EventApplicationState build(Event event) => _state;
}
