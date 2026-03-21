import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;
  late MockVerificationRepository mockVerificationRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();
    mockVerificationRepo = MockVerificationRepository();
  });

  Party makeParty({
    String id = 'party-1',
    List<String> verificationIds = const [],
  }) {
    return Party(
      id: id,
      partnerId: 'partner-1',
      title: 'Test Party',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      requiredVerificationIds: verificationIds,
    );
  }

  ProviderContainer makeContainer({
    Party? party,
    Exception? partyError,
  }) {
    if (partyError != null) {
      when(() => mockPartyRepo.getPartyById(any())).thenThrow(partyError);
    } else {
      when(
        () => mockPartyRepo.getPartyById(any()),
      ).thenAnswer((_) async => party ?? makeParty());
    }

    when(
      () => mockTicketRepo.getTicketTemplatesByPartyId(any()),
    ).thenAnswer((_) async => []);

    when(
      () => mockLocationRepo.getLocationById(any()),
    ).thenAnswer((_) async => null);

    when(
      () => mockVerificationRepo.getVerificationsByIds(any()),
    ).thenAnswer((_) async => []);

    return createContainer(
      overrides: [
        partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        verificationRepositoryProvider.overrideWithValue(mockVerificationRepo),
      ],
    );
  }

  group('partyDetailProvider', () {
    test('returns party when found', () async {
      final party = makeParty(id: 'party-1');
      final container = makeContainer(party: party);

      final result = await container.read(partyDetailProvider('party-1').future);
      expect(result.id, 'party-1');
    });

    test('returns party with correct partnerId', () async {
      final party = makeParty(id: 'party-2');
      when(
        () => mockPartyRepo.getPartyById('party-2'),
      ).thenAnswer((_) async => party);

      final container = makeContainer(party: party);
      final result = await container.read(partyDetailProvider('party-2').future);
      expect(result.partnerId, 'partner-1');
    });
  });

  group('partyTicketsProvider', () {
    test('returns empty list when no tickets', () async {
      when(
        () => mockTicketRepo.getTicketTemplatesByPartyId('party-1'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result = await container.read(partyTicketsProvider('party-1').future);
      expect(result, isEmpty);
    });
  });

  group('locationDetailProvider', () {
    test('returns null when locationId is null', () async {
      final container = makeContainer();
      final result = await container.read(locationDetailProvider(null).future);
      expect(result, isNull);
    });

    test('returns null when locationId is empty', () async {
      final container = makeContainer();
      final result = await container.read(locationDetailProvider('').future);
      expect(result, isNull);
    });
  });

  group('partyVerificationsProvider', () {
    test('returns empty list when party has no required verifications', () async {
      final party = makeParty(verificationIds: []);
      final container = makeContainer(party: party);

      final result =
          await container.read(partyVerificationsProvider('party-1').future);
      expect(result, isEmpty);
    });
  });
}
