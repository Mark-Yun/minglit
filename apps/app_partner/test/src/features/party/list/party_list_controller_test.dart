import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Party _makeParty(String id) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Party $id',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockPartnerRepository mockPartnerRepo;
  late MockPartyRepository mockPartyRepo;

  setUp(() {
    mockPartnerRepo = MockPartnerRepository();
    mockPartyRepo = MockPartyRepository();
  });

  group('partyList', () {
    test('returns parties for first managed partner', () async {
      when(() => mockPartnerRepo.getMyManagedPartners()).thenAnswer(
        (_) async => [const Partner(id: 'partner-1', name: 'Test Partner')],
      );
      final parties = [_makeParty('p-1'), _makeParty('p-2')];
      when(
        () => mockPartyRepo.getPartiesByPartnerId('partner-1'),
      ).thenAnswer((_) async => parties);

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(partyListProvider, (_, _) {});
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyListProvider);
      expect(state.value, hasLength(2));
      expect(state.value!.first.id, 'p-1');
    });

    test('returns empty list when no managed partners', () async {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(partyListProvider, (_, _) {});
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyListProvider);
      expect(state.value, isEmpty);
      verifyNever(() => mockPartyRepo.getPartiesByPartnerId(any()));
    });

    test('propagates error when partner fetch fails', () async {
      when(
        () => mockPartnerRepo.getMyManagedPartners(),
      ).thenThrow(Exception('network error'));

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(partyListProvider, (_, _) {});
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyListProvider);
      expect(state.hasError, isTrue);
    });

    test('propagates error when party fetch fails', () async {
      when(() => mockPartnerRepo.getMyManagedPartners()).thenAnswer(
        (_) async => [const Partner(id: 'partner-1', name: 'Test Partner')],
      );
      when(
        () => mockPartyRepo.getPartiesByPartnerId('partner-1'),
      ).thenThrow(Exception('db error'));

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        ],
      );
      final sub = container.listen(partyListProvider, (_, _) {});
      addTearDown(sub.close);

      await pump();

      final state = container.read(partyListProvider);
      expect(state.hasError, isTrue);
    });
  });
}
