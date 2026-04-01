@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'golden_test_helpers.dart';

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

class _MockPolicyRepository extends Mock implements PolicyRepository {}

void main() {
  late _MockPolicyRepository mockPolicyRepository;

  const eventId = 'event-golden';
  final baseTime = DateTime(2026, 4, 12, 18);
  final location = Location(
    id: 'location-1',
    partnerId: 'partner-1',
    name: '밍글릿 라운지',
    address: '서울 강남구 테헤란로 123',
    createdAt: baseTime,
    updatedAt: baseTime,
  );
  const partner = Partner(
    id: 'partner-1',
    name: '밍글릿 소셜 클럽',
    introduction: '프리미엄 소셜 이벤트를 운영합니다.',
  );
  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '봄 시즌 네트워킹 파티',
    createdAt: baseTime,
    updatedAt: baseTime,
    location: location,
    partner: partner,
    description: const {
      'ops': [
        {'insert': '도심 한가운데에서 열리는 프리미엄 네트워킹 이벤트입니다.\n'},
        {'insert': '드레스 코드: Smart Casual\n'},
      ],
    },
  );
  final ticket = Ticket(
    id: 'ticket-1',
    name: '얼리버드',
    price: 39000,
    quantity: 40,
    soldCount: 24,
    createdAt: baseTime,
    updatedAt: baseTime,
    targetEntryGroupIds: const ['group-1'],
  );
  final event = Event(
    id: eventId,
    partyId: party.id,
    title: party.title,
    startTime: DateTime(2026, 4, 25, 19),
    endTime: DateTime(2026, 4, 25, 23),
    createdAt: baseTime,
    updatedAt: baseTime,
    location: location,
    party: party,
    tickets: [ticket],
    entryGroups: const [
      EntryGroup(
        id: 'group-1',
        eventId: eventId,
        label: '남성 20대 후반',
        gender: 'male',
        birthYearMin: 1992,
        birthYearMax: 1999,
      ),
    ],
  );

  setUpAll(() async {
    await initGoldenDeps();
  });

  setUp(() {
    mockPolicyRepository = _MockPolicyRepository();
    when(
      () => mockPolicyRepository.getRefundPolicy(),
    ).thenAnswer(
      (_) async => {
        'grace_period_hours': 2,
        'cutoff_days': 7,
      },
    );
  });

  GoldenTestScenario scenario({
    required String name,
    required AdmissionState admissionState,
  }) {
    return GoldenTestScenario(
      name: name,
      child: SizedBox(
        width: 390,
        height: 844,
        child: GoldenPageWrapper(
          page: const EventDetailPage(eventId: eventId),
          overrides: [
            eventDetailControllerProvider(eventId).overrideWith(
              () => _MockEventDetailController(event),
            ),
            eventAdmissionControllerProvider(event).overrideWith(
              () => _MockAdmissionController(admissionState),
            ),
            entryGroupParticipantCountsProvider(eventId).overrideWith(
              (ref) async => const {'group-1': 24},
            ),
            verificationsByIdsProvider('').overrideWith((_) async => []),
            policyRepositoryProvider.overrideWith((_) => mockPolicyRepository),
          ],
        ),
      ),
    );
  }

  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'EventDetailPage admission states',
    fileName: 'event_detail_page_states',
    pumpBeforeTest: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        scenario(
          name: 'open',
          admissionState: AdmissionState(
            status: EventAdmissionStatus.eligible,
          ),
        ),
        scenario(
          name: 'sold out',
          admissionState: AdmissionState(
            status: EventAdmissionStatus.notEligible,
            ineligibleReason: '매진된 이벤트입니다.',
          ),
        ),
        scenario(
          name: 'closed',
          admissionState: AdmissionState(
            status: EventAdmissionStatus.notEligible,
            ineligibleReason: '신청이 마감된 이벤트입니다.',
          ),
        ),
      ],
    ),
  );
}
