// Ref #1315: 이벤트 생성 wizard 전체 플로우 통합 테스트
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/test_utils.dart';

// ---------------------------------------------------------------------------
// Fallback values required by mocktail for `any()` matchers on custom types.
// ---------------------------------------------------------------------------
class _FakeParty extends Fake implements Party {}

class _FakeTicketTemplate extends Fake implements TicketTemplate {}

class _FakeLocation extends Fake implements Location {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
ProviderContainer _buildContainer({
  required MockPartnerRepository partnerRepo,
  required MockPartyRepository partyRepo,
  required MockTicketRepository ticketRepo,
  required MockLocationRepository locationRepo,
}) {
  return createContainer(
    overrides: [
      partnerRepositoryProvider.overrideWithValue(partnerRepo),
      partyRepositoryProvider.overrideWithValue(partyRepo),
      ticketRepositoryProvider.overrideWithValue(ticketRepo),
      locationRepositoryProvider.overrideWithValue(locationRepo),
    ],
  );
}

/// Fills the controller with a fully valid state that passes all validationErrors.
void _fillValidState(PartyCreateWizardController notifier) {
  notifier
    ..updateTitle('테스트 파티')
    ..updateDescription({
      'ops': [
        {'insert': '파티 설명입니다.\n'},
      ],
    })
    ..updateLocation(
      Location(
        id: 'loc_1',
        partnerId: 'partner_1',
        name: '테스트 장소',
        address: '서울시 강남구 테스트로 1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    )
    ..toggleContactMethod('phone')
    ..updateContactPhone('010-0000-0000')
    ..addEntryGroup(
      const EntryGroupTemplate(id: 'eg_1', partyId: '', label: '일반'),
    )
    ..addTicket(
      TicketTemplate(
        id: '',
        partyId: '',
        name: '일반 티켓',
        price: 10000,
        quantity: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockPartnerRepository mockPartnerRepo;
  late MockPartyRepository mockPartyRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;

  setUpAll(() {
    registerFallbackValue(_FakeParty());
    registerFallbackValue(_FakeTicketTemplate());
    registerFallbackValue(_FakeLocation());
  });

  setUp(() {
    mockPartnerRepo = MockPartnerRepository();
    mockPartyRepo = MockPartyRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();
  });

  group('PartyCreateWizardController', () {
    // -----------------------------------------------------------------------
    // TC-1: 초기 상태 검증
    // -----------------------------------------------------------------------
    test('1. 초기 상태는 basicInfo 단계이며 모든 필드가 비어 있다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final state = container.read(partyCreateWizardControllerProvider);

      expect(state.currentStep, PartyCreateStep.basicInfo);
      expect(state.title, '');
      expect(state.description, isEmpty);
      expect(state.entryGroups, isEmpty);
      expect(state.tickets, isEmpty);
      expect(state.selectedLocation, isNull);
      expect(state.enabledContactMethods, isEmpty);
    });

    // -----------------------------------------------------------------------
    // TC-2: 제목 입력 → 상태 반영
    // -----------------------------------------------------------------------
    test('2. 제목 입력 시 state.title이 업데이트된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.updateTitle('멋진 파티');

      expect(
        container.read(partyCreateWizardControllerProvider).title,
        '멋진 파티',
      );
    });

    // -----------------------------------------------------------------------
    // TC-3: 단계 이동 — nextStep / previousStep
    // -----------------------------------------------------------------------
    test('3. nextStep()은 다음 단계로 이동하고, previousStep()은 이전 단계로 돌아온다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      // basicInfo → location
      notifier.nextStep();
      expect(
        container.read(partyCreateWizardControllerProvider).currentStep,
        PartyCreateStep.location,
      );

      // location → basicInfo
      notifier.previousStep();
      expect(
        container.read(partyCreateWizardControllerProvider).currentStep,
        PartyCreateStep.basicInfo,
      );
    });

    // -----------------------------------------------------------------------
    // TC-4: previousStep()은 첫 번째 단계에서 단계를 변경하지 않는다
    // -----------------------------------------------------------------------
    test('4. previousStep()을 첫 단계에서 호출해도 basicInfo 단계 유지 (뒤로가기 보호)', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );

      container
          .read(partyCreateWizardControllerProvider.notifier)
          .previousStep();

      expect(
        container.read(partyCreateWizardControllerProvider).currentStep,
        PartyCreateStep.basicInfo,
      );
    });

    // -----------------------------------------------------------------------
    // TC-5: nextStep()은 마지막 단계에서 단계를 변경하지 않는다
    // -----------------------------------------------------------------------
    test('5. nextStep()을 마지막 단계(review)에서 호출해도 review 단계 유지', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.setStep(PartyCreateStep.review);
      notifier.nextStep();

      expect(
        container.read(partyCreateWizardControllerProvider).currentStep,
        PartyCreateStep.review,
      );
    });

    // -----------------------------------------------------------------------
    // TC-6: 엔트리 그룹 추가/삭제
    // -----------------------------------------------------------------------
    test('6. 엔트리 그룹 추가 후 제거 시 리스트가 비어 있다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      const group = EntryGroupTemplate(id: 'eg_1', partyId: '', label: '남성');
      notifier.addEntryGroup(group);

      expect(
        container.read(partyCreateWizardControllerProvider).entryGroups.length,
        1,
      );

      notifier.removeEntryGroup('eg_1');

      expect(
        container.read(partyCreateWizardControllerProvider).entryGroups,
        isEmpty,
      );
    });

    // -----------------------------------------------------------------------
    // TC-7: 티켓 추가 → maxParticipants 자동 계산
    // -----------------------------------------------------------------------
    test('7. 티켓 추가 시 maxParticipants는 티켓 수량의 합계로 자동 계산된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.addTicket(
        TicketTemplate(
          id: '',
          partyId: '',
          name: '일반',
          price: 0,
          quantity: 20,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      notifier.addTicket(
        TicketTemplate(
          id: '',
          partyId: '',
          name: 'VIP',
          price: 50000,
          quantity: 5,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(
        container.read(partyCreateWizardControllerProvider).maxParticipants,
        25,
      );
    });

    // -----------------------------------------------------------------------
    // TC-8: 무료 이벤트 (가격 0원) — 검증 오류 없음
    // -----------------------------------------------------------------------
    test('8. 가격 0원 티켓은 유효하며 validationErrors에 영향을 주지 않는다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      _fillValidState(notifier);

      // 기존 티켓을 가격 0원으로 교체
      notifier.removeTicket(0);
      notifier.addTicket(
        TicketTemplate(
          id: '',
          partyId: '',
          name: '무료 티켓',
          price: 0,
          quantity: 10,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final errors = notifier.validationErrors;
      expect(errors, isEmpty);
    });

    // -----------------------------------------------------------------------
    // TC-9: 필수 필드 누락 → 발행 버튼 비활성화 + 에러 표시
    // -----------------------------------------------------------------------
    test('9. 모든 필수 필드가 비어 있으면 validationErrors가 비어 있지 않다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      final errors = notifier.validationErrors;

      expect(errors, isNotEmpty);
    });

    test('9b. 제목이 비어 있으면 해당 에러 메시지가 포함된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      final errors = notifier.validationErrors;
      expect(errors.any((e) => e.contains('제목')), isTrue);
    });

    test('9c. 엔트리 그룹이 없으면 해당 에러 메시지가 포함된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      final errors = notifier.validationErrors;
      expect(errors.any((e) => e.contains('입장 그룹')), isTrue);
    });

    test('9d. 티켓이 없으면 해당 에러 메시지가 포함된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      final errors = notifier.validationErrors;
      expect(errors.any((e) => e.contains('티켓')), isTrue);
    });

    // -----------------------------------------------------------------------
    // TC-10: 전체 입력 완료 → validationErrors가 비어 있다 (발행 버튼 활성화)
    // -----------------------------------------------------------------------
    test('10. 모든 필수 필드 입력 완료 시 validationErrors가 비어 있다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      _fillValidState(notifier);

      expect(notifier.validationErrors, isEmpty);
    });

    // -----------------------------------------------------------------------
    // TC-11: 발행 성공 → status가 AsyncData(null)
    // -----------------------------------------------------------------------
    test('11. 모든 필드가 유효하면 submit() 후 status가 AsyncData(null)이다', () async {
      const partnerId = 'partner_1';
      final createdParty = Party(
        id: 'party_new',
        partnerId: partnerId,
        title: '테스트 파티',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final createdLocation = Location(
        id: 'loc_created',
        partnerId: partnerId,
        name: '테스트 장소',
        address: '서울시 강남구 테스트로 1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final createdTicket = TicketTemplate(
        id: 'tkt_1',
        partyId: 'party_new',
        name: '일반 티켓',
        price: 10000,
        quantity: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => [const Partner(id: partnerId, name: '테스트 파트너')]);
      when(
        () => mockLocationRepo.createLocation(any()),
      ).thenAnswer((_) async => createdLocation);
      when(
        () => mockPartyRepo.createParty(any(), extraFields: any(named: 'extraFields')),
      ).thenAnswer((_) async => createdParty);
      when(
        () => mockTicketRepo.createTicketTemplate(any()),
      ).thenAnswer((_) async => createdTicket);

      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      _fillValidState(notifier);
      await notifier.submit();

      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.status, isA<AsyncData<void>>());
      expect(state.status.hasValue, isTrue);
      expect(state.status.hasError, isFalse);
    });

    // -----------------------------------------------------------------------
    // TC-12: 발행 실패 → status가 AsyncError
    // -----------------------------------------------------------------------
    test('12. 파트너 정보 없으면 submit() 후 status가 AsyncError이다', () async {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => []);

      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      _fillValidState(notifier);
      await notifier.submit();

      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.status, isA<AsyncError<void>>());
    });

    // -----------------------------------------------------------------------
    // TC-13: 중간 이탈 → 이전 입력 보존 (뒤로가기)
    // -----------------------------------------------------------------------
    test('13. 단계를 앞뒤로 이동해도 이전에 입력한 데이터가 보존된다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      // Step 1에서 데이터 입력
      notifier.updateTitle('보존 테스트 파티');

      // Step 2로 이동 후 Step 1으로 복귀
      notifier
        ..nextStep()
        ..previousStep();

      // 데이터 보존 확인
      expect(
        container.read(partyCreateWizardControllerProvider).title,
        '보존 테스트 파티',
      );
    });

    // -----------------------------------------------------------------------
    // TC-14: setStep() 직접 이동
    // -----------------------------------------------------------------------
    test('14. setStep()으로 임의 단계로 직접 이동할 수 있다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );

      container
          .read(partyCreateWizardControllerProvider.notifier)
          .setStep(PartyCreateStep.tickets);

      expect(
        container.read(partyCreateWizardControllerProvider).currentStep,
        PartyCreateStep.tickets,
      );
    });

    // -----------------------------------------------------------------------
    // TC-15: 연락처 토글 — enabledContactMethods 상태 전환
    // -----------------------------------------------------------------------
    test('15. toggleContactMethod()는 연락처 활성화/비활성화를 토글한다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.toggleContactMethod('phone');
      expect(
        container
            .read(partyCreateWizardControllerProvider)
            .enabledContactMethods,
        contains('phone'),
      );

      notifier.toggleContactMethod('phone');
      expect(
        container
            .read(partyCreateWizardControllerProvider)
            .enabledContactMethods,
        isNot(contains('phone')),
      );
    });

    // -----------------------------------------------------------------------
    // TC-16: 공개 범위 설정
    // -----------------------------------------------------------------------
    test('16. setVisibility()로 visibility를 private/public으로 변경할 수 있다', () {
      final container = _buildContainer(
        partnerRepo: mockPartnerRepo,
        partyRepo: mockPartyRepo,
        ticketRepo: mockTicketRepo,
        locationRepo: mockLocationRepo,
      );
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.setVisibility('private');
      expect(
        container.read(partyCreateWizardControllerProvider).visibility,
        'private',
      );

      notifier.setVisibility('public');
      expect(
        container.read(partyCreateWizardControllerProvider).visibility,
        'public',
      );
    });
  });
}
