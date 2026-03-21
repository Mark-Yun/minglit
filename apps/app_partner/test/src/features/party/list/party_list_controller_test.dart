import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockPartnerRepository mockPartnerRepo;
  late MockPartyRepository mockPartyRepo;

  setUp(() {
    mockPartnerRepo = MockPartnerRepository();
    mockPartyRepo = MockPartyRepository();
  });

  ProviderContainer makeContainer({
    List<Partner> partners = const [],
    List<Party> parties = const [],
    Exception? partnerError,
  }) {
    if (partnerError != null) {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenThrow(partnerError);
    } else {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => partners);
    }

    when(
      () => mockPartyRepo.getPartiesByPartnerId(any()),
    ).thenAnswer((_) async => parties);

    return createContainer(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
        partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      ],
    );
  }

  group('partyListProvider', () {
    test('returns empty list when user has no managed partners', () async {
      final container = makeContainer(partners: []);

      final result = await container.read(partyListProvider.future);
      expect(result, isEmpty);
      verifyNever(() => mockPartyRepo.getPartiesByPartnerId(any()));
    });

    test('returns parties for first managed partner', () async {
      final partner = const Partner(id: 'partner-1', name: 'Partner A');
      final parties = [
        Party(
          id: 'p1',
          partnerId: 'partner-1',
          title: 'Party 1',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final container = makeContainer(partners: [partner], parties: parties);

      final result = await container.read(partyListProvider.future);
      expect(result.length, 1);
      expect(result.first.id, 'p1');
      verify(() => mockPartyRepo.getPartiesByPartnerId('partner-1')).called(1);
    });

    test('uses only the first partner when multiple exist', () async {
      final partners = [
        const Partner(id: 'partner-1', name: 'Partner A'),
        const Partner(id: 'partner-2', name: 'Partner B'),
      ];

      final container = makeContainer(partners: partners, parties: []);

      await container.read(partyListProvider.future);
      verify(() => mockPartyRepo.getPartiesByPartnerId('partner-1')).called(1);
      verifyNever(() => mockPartyRepo.getPartiesByPartnerId('partner-2'));
    });

    test('returns parties with correct ids for partner', () async {
      final partner = const Partner(id: 'partner-1', name: 'Partner A');
      final parties = [
        Party(
          id: 'p2',
          partnerId: 'partner-1',
          title: 'Party 2',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
        Party(
          id: 'p3',
          partnerId: 'partner-1',
          title: 'Party 3',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final container = makeContainer(partners: [partner], parties: parties);
      final result = await container.read(partyListProvider.future);
      expect(result.map((p) => p.id).toList(), containsAll(['p2', 'p3']));
    });
  });
}
