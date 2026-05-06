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

Event _makeEvent({
  required String id,
  required String partyId,
  required String status,
  required DateTime startTime,
}) {
  return Event(
    id: id,
    partyId: partyId,
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 2)),
    createdAt: startTime.subtract(const Duration(days: 7)),
    updatedAt: startTime.subtract(const Duration(days: 7)),
    status: status,
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
      when(
        () => mockPartyRepo.getEventsByPartyId(any()),
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
      expect(state.value, hasLength(2));
      // Fix #2201: controller returns PartyWithStats, not Party directly
      expect(state.value!.first.party.id, 'p-1');
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

    // Fix #2201: verify PartyWithStats aggregation contract
    test(
      'aggregates completedCount, upcomingCount, nextEvent correctly',
      () async {
        when(() => mockPartnerRepo.getMyManagedPartners()).thenAnswer(
          (_) async => [const Partner(id: 'partner-1', name: 'Test Partner')],
        );
        when(
          () => mockPartyRepo.getPartiesByPartnerId('partner-1'),
        ).thenAnswer((_) async => [_makeParty('p-1')]);

        final now = DateTime.now();
        final events = [
          _makeEvent(
            id: 'e-completed',
            partyId: 'p-1',
            status: 'completed',
            startTime: now.subtract(const Duration(days: 10)),
          ),
          // nearer future → becomes nextEvent
          _makeEvent(
            id: 'e-active-near',
            partyId: 'p-1',
            status: 'active',
            startTime: now.add(const Duration(days: 2)),
          ),
          _makeEvent(
            id: 'e-scheduled-far',
            partyId: 'p-1',
            status: 'scheduled',
            startTime: now.add(const Duration(days: 7)),
          ),
          // cancelled must NOT count as completed or upcoming
          _makeEvent(
            id: 'e-cancelled',
            partyId: 'p-1',
            status: 'cancelled',
            startTime: now.subtract(const Duration(days: 3)),
          ),
        ];
        when(
          () => mockPartyRepo.getEventsByPartyId('p-1'),
        ).thenAnswer((_) async => events);

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
        expect(state.hasValue, isTrue);
        final entry = state.value!.first;
        expect(entry.completedCount, 1, reason: 'only status=completed counts');
        expect(
          entry.upcomingCount,
          2,
          reason: 'active+scheduled with future startTime counts',
        );
        expect(
          entry.nextEvent?.id,
          'e-active-near',
          reason: 'nearest future event is selected as nextEvent',
        );
      },
    );

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
