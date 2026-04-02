@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 4, 2, 18);
  final baseState = PartyCreateWizardState(
    title: '금요 밍글 살롱',
    description: const {
      'ops': [
        {'insert': '강남 프라이빗 라운지에서 열리는 소셜 이벤트입니다.\n'},
        {'insert': '드레스 코드와 웰컴 드링크가 제공됩니다.\n'},
      ],
    },
    selectedLocation: Location(
      id: 'location_1',
      partnerId: 'partner_1',
      name: '밍릿 라운지',
      address: '서울특별시 강남구 테헤란로 123',
      createdAt: baseTime,
      updatedAt: baseTime,
      latitude: 37.4981,
      longitude: 127.0276,
    ),
    addressDetail: '8층 루프탑 홀',
    directionsGuide: '2호선 역삼역 3번 출구에서 도보 3분',
    minConfirmedCount: 12,
    maxParticipants: 24,
    contactPhone: '010-1234-5678',
    contactEmail: 'party@minglit.com',
    contactKakao: 'minglitparty',
    enabledContactMethods: {'phone', 'email', 'kakao'},
    entryGroups: [
      EntryGroupTemplate(
        id: 'group_female',
        partyId: 'party_1',
        label: '여성 일반',
        gender: 'female',
        birthYearMin: 1994,
        birthYearMax: 2001,
        createdAt: baseTime,
        updatedAt: baseTime,
      ),
      EntryGroupTemplate(
        id: 'group_male',
        partyId: 'party_1',
        label: '남성 일반',
        gender: 'male',
        birthYearMin: 1991,
        birthYearMax: 1999,
        requiredVerificationIds: const ['career'],
        createdAt: baseTime,
        updatedAt: baseTime,
      ),
    ],
    tickets: [
      TicketTemplate(
        id: 'ticket_1',
        partyId: 'party_1',
        name: '얼리버드',
        description: '웰컴 드링크 1잔 포함',
        price: 35000,
        quantity: 10,
        targetEntryGroupIds: const ['group_female', 'group_male'],
        createdAt: baseTime,
        updatedAt: baseTime,
      ),
      TicketTemplate(
        id: 'ticket_2',
        partyId: 'party_1',
        name: '일반 입장권',
        description: '현장 입장 및 자유 네트워킹',
        price: 45000,
        quantity: 14,
        targetEntryGroupIds: const ['group_female', 'group_male'],
        createdAt: baseTime,
        updatedAt: baseTime,
      ),
    ],
  );

  // goldenTest registers scenarios synchronously during main().
  // ignore: discarded_futures
  goldenTest(
    'PartyCreateWizardPage key steps',
    fileName: 'party_create_wizard_page_key_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        _partyCreateScenario(
          name: 'step 1 basic info',
          initialState: baseState,
          step: PartyCreateStep.basicInfo,
        ),
        _partyCreateScenario(
          name: 'step 6 review',
          initialState: baseState,
          step: PartyCreateStep.review,
        ),
      ],
    ),
  );
}

GoldenTestScenario _partyCreateScenario({
  required String name,
  required PartyCreateWizardState initialState,
  required PartyCreateStep step,
}) {
  return GoldenTestScenario(
    name: name,
    child: SizedBox(
      width: 390,
      height: 844,
      child: PartnerGoldenPageWrapper(
        page: _PartyCreateStepHarness(step: step),
        overrides: [
          partyCreateWizardControllerProvider.overrideWith(
            () => _PartyCreateWizardGoldenController(initialState),
          ),
        ],
      ),
    ),
  );
}

class _PartyCreateStepHarness extends ConsumerStatefulWidget {
  const _PartyCreateStepHarness({required this.step});

  final PartyCreateStep step;

  @override
  ConsumerState<_PartyCreateStepHarness> createState() =>
      _PartyCreateStepHarnessState();
}

class _PartyCreateStepHarnessState
    extends ConsumerState<_PartyCreateStepHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(partyCreateWizardControllerProvider.notifier)
          .setStep(widget.step);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const PartyCreateWizardPage();
  }
}

class _PartyCreateWizardGoldenController extends PartyCreateWizardController {
  _PartyCreateWizardGoldenController(this._state);

  final PartyCreateWizardState _state;

  @override
  PartyCreateWizardState build() => _state;

  @override
  Future<void> loadForEdit(String partyId) async {}

  @override
  Future<void> submit() async {}
}
