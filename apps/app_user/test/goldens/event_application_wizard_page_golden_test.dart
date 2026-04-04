@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/admission/event_application_wizard_page.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../integration/utils/test_mocks.dart';
import 'golden_test_helpers.dart';

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

void main() {
  const eventId = 'event-application-golden';
  final baseTime = DateTime(2026, 4, 12, 18);
  final ticket = Ticket(
    id: 'ticket-vip',
    name: 'VIP 입장권',
    price: 59000,
    createdAt: baseTime,
    updatedAt: baseTime,
    targetEntryGroupIds: const ['group-1'],
  );
  final event = Event(
    id: eventId,
    partyId: 'party-1',
    title: '봄 시즌 네트워킹 파티',
    startTime: DateTime(2026, 4, 25, 19),
    endTime: DateTime(2026, 4, 25, 23),
    createdAt: baseTime,
    updatedAt: baseTime,
    tickets: [ticket],
    entryGroups: const [
      EntryGroup(
        id: 'group-1',
        eventId: eventId,
        label: '직장인 전용',
        requiredVerificationIds: ['career-proof'],
      ),
    ],
  );
  final mockUser = createMockUserForTest();
  const verification = Verification(
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

  setUpAll(() async {
    await initGoldenDeps();
  });

  GoldenTestScenario scenario({
    required String name,
    required EventApplicationState state,
  }) {
    return GoldenTestScenario(
      name: name,
      child: SizedBox(
        width: 390,
        height: 844,
        child: GoldenPageWrapper(
          currentUser: mockUser,
          page: const EventApplicationWizardPage(eventId: eventId),
          overrides: [
            eventDetailControllerProvider(eventId).overrideWith(
              () => _MockEventDetailController(event),
            ),
            eventApplicationControllerProvider(event).overrideWith(
              () => _MockApplicationController(state),
            ),
            verificationsByIdsProvider('career-proof').overrideWith(
              (_) async => [verification],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'EventApplicationWizardPage steps',
    fileName: 'event_application_wizard_page_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        scenario(
          name: 'verification step',
          state: EventApplicationState(
            step: EventApplicationStep.verification,
            status: EventApplicationStatus.initial,
            selectedTicket: ticket,
          ),
        ),
        scenario(
          name: 'payment step',
          state: EventApplicationState(
            step: EventApplicationStep.payment,
            status: EventApplicationStatus.initial,
            selectedTicket: ticket,
          ),
        ),
      ],
    ),
  );
}
