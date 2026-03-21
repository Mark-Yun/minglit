import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockTicketRepository mockTicketRepo;

  setUp(() {
    mockTicketRepo = MockTicketRepository();
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
      ],
    );
  }

  group('eventTicketsProvider', () {
    test('returns tickets for the given event', () async {
      final tickets = [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          name: 'General',
          price: 10000,
          quantity: 50,
          soldCount: 0,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      when(
        () => mockTicketRepo.getTicketsByEventId('event-1'),
      ).thenAnswer((_) async => tickets);

      final container = makeContainer();
      final result =
          await container.read(eventTicketsProvider('event-1').future);

      expect(result.length, 1);
      expect(result.first.id, 'ticket-1');
    });

    test('returns empty list when event has no tickets', () async {
      when(
        () => mockTicketRepo.getTicketsByEventId('event-empty'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result =
          await container.read(eventTicketsProvider('event-empty').future);

      expect(result, isEmpty);
    });

    test('returns different results for different eventIds', () async {
      final ticketsA = [
        Ticket(
          id: 'ticket-a',
          eventId: 'event-a',
          name: 'VIP',
          price: 50000,
          quantity: 10,
          soldCount: 0,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      when(
        () => mockTicketRepo.getTicketsByEventId('event-a'),
      ).thenAnswer((_) async => ticketsA);
      when(
        () => mockTicketRepo.getTicketsByEventId('event-b'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final resultA =
          await container.read(eventTicketsProvider('event-a').future);
      final resultB =
          await container.read(eventTicketsProvider('event-b').future);

      expect(resultA.length, 1);
      expect(resultB, isEmpty);
    });
  });
}
