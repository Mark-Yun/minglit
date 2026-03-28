import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

Ticket _makeTicket(String id, {String eventId = 'event_1'}) {
  final now = DateTime.now();
  return Ticket(
    id: id,
    name: 'Ticket $id',
    eventId: eventId,
    price: 10000,
    quantity: 50,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockTicketRepository mockTicketRepo;

  setUp(() {
    mockTicketRepo = MockTicketRepository();
  });

  group('eventTickets', () {
    test('returns tickets for given eventId', () async {
      final tickets = [_makeTicket('t1'), _makeTicket('t2')];
      when(
        () => mockTicketRepo.getTicketsByEventId('event_1'),
      ).thenAnswer((_) async => tickets);

      final container = createContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        ],
      );

      final result = await container.read(
        eventTicketsProvider('event_1').future,
      );

      expect(result, hasLength(2));
      expect(result.first.id, 't1');
      expect(result.last.id, 't2');
      verify(() => mockTicketRepo.getTicketsByEventId('event_1')).called(1);
    });

    test('returns empty list when no tickets exist', () async {
      when(
        () => mockTicketRepo.getTicketsByEventId('event_empty'),
      ).thenAnswer((_) async => <Ticket>[]);

      final container = createContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        ],
      );

      final result = await container.read(
        eventTicketsProvider('event_empty').future,
      );

      expect(result, isEmpty);
    });

    test('propagates error when repository throws', () async {
      when(
        () => mockTicketRepo.getTicketsByEventId('event_err'),
      ).thenAnswer((_) async => throw Exception('DB error'));

      final container = createContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        ],
      );

      final sub = container.listen(
        eventTicketsProvider('event_err'),
        (_, _) {},
      );
      addTearDown(sub.close);

      // Wait for the provider to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventTicketsProvider('event_err'));
      expect(state.hasError, isTrue);
    });
  });
}
