import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Party _makeParty(String id, {List<String> verificationIds = const []}) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
    requiredVerificationIds: verificationIds,
  );
}

TicketTemplate _makeTicket(String id) {
  final now = DateTime.now();
  return TicketTemplate(
    id: id,
    partyId: 'party-1',
    name: 'Ticket $id',
    createdAt: now,
    updatedAt: now,
    price: 10000,
  );
}

Location _makeLocation(String id) {
  final now = DateTime.now();
  return Location(
    id: id,
    partnerId: 'partner-1',
    name: 'Test Location',
    address: '서울시 강남구',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;
  late MockVerificationRepository mockVerifRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();
    mockVerifRepo = MockVerificationRepository();
  });

  group('partyDetail', () {
    test('returns party when found', () async {
      final party = _makeParty('party-1');
      when(
        () => mockPartyRepo.getPartyById('party-1'),
      ).thenAnswer((_) async => party);

      final container = createContainer(
        overrides: [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(
        partyDetailProvider('party-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyDetailProvider('party-1'));
      expect(state.value, isNotNull);
      expect(state.value!.id, 'party-1');
    });

    test('throws when party not found', () async {
      when(
        () => mockPartyRepo.getPartyById('missing'),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(
        partyDetailProvider('missing'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyDetailProvider('missing'));
      expect(state.hasError, isTrue);
    });
  });

  group('partyTickets', () {
    test('returns ticket list', () async {
      final tickets = [_makeTicket('t-1'), _makeTicket('t-2')];
      when(
        () => mockTicketRepo.getTicketTemplatesByPartyId('party-1'),
      ).thenAnswer((_) async => tickets);

      final container = createContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        ],
      );
      final sub = container.listen(
        partyTicketsProvider('party-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyTicketsProvider('party-1'));
      expect(state.value, hasLength(2));
    });

    test('returns empty list when no tickets', () async {
      when(
        () => mockTicketRepo.getTicketTemplatesByPartyId('party-1'),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        ],
      );
      final sub = container.listen(
        partyTicketsProvider('party-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyTicketsProvider('party-1'));
      expect(state.value, isEmpty);
    });
  });

  group('locationDetail', () {
    test('returns location when id provided', () async {
      final location = _makeLocation('loc-1');
      when(
        () => mockLocationRepo.getLocationById('loc-1'),
      ).thenAnswer((_) async => location);

      final container = createContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        ],
      );
      final sub = container.listen(
        locationDetailProvider('loc-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(locationDetailProvider('loc-1'));
      expect(state.value, isNotNull);
      expect(state.value!.id, 'loc-1');
    });

    test('returns null when id is null', () async {
      final container = createContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        ],
      );
      final sub = container.listen(
        locationDetailProvider(null),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(locationDetailProvider(null));
      expect(state.value, isNull);
      verifyNever(() => mockLocationRepo.getLocationById(any()));
    });

    test('returns null when id is empty', () async {
      final container = createContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        ],
      );
      final sub = container.listen(
        locationDetailProvider(''),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(locationDetailProvider(''));
      expect(state.value, isNull);
      verifyNever(() => mockLocationRepo.getLocationById(any()));
    });
  });

  group('partyVerifications', () {
    test('returns verifications for party with required ids', () async {
      final party = _makeParty('party-1', verificationIds: ['v-1', 'v-2']);
      when(
        () => mockPartyRepo.getPartyById('party-1'),
      ).thenAnswer((_) async => party);

      final verifications = [
        const Verification(
          id: 'v-1',
          category: VerificationCategory.career,
          internalName: 'id_verify',
          displayName: '본인인증',
        ),
        const Verification(
          id: 'v-2',
          category: VerificationCategory.career,
          internalName: 'career',
          displayName: '직장인증',
        ),
      ];
      when(
        () => mockVerifRepo.getVerificationsByIds(['v-1', 'v-2']),
      ).thenAnswer((_) async => verifications);

      final container = createContainer(
        overrides: [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          verificationRepositoryProvider.overrideWithValue(mockVerifRepo),
        ],
      );
      final sub = container.listen(
        partyVerificationsProvider('party-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyVerificationsProvider('party-1'));
      expect(state.value, hasLength(2));
    });

    test('returns empty list when no required verification ids', () async {
      final party = _makeParty('party-1');
      when(
        () => mockPartyRepo.getPartyById('party-1'),
      ).thenAnswer((_) async => party);

      final container = createContainer(
        overrides: [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          verificationRepositoryProvider.overrideWithValue(mockVerifRepo),
        ],
      );
      final sub = container.listen(
        partyVerificationsProvider('party-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyVerificationsProvider('party-1'));
      expect(state.value, isEmpty);
      verifyNever(() => mockVerifRepo.getVerificationsByIds(any()));
    });
  });
}
