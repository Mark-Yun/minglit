import 'package:app_partner/src/features/ticket/logic/ticket_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

void main() {
  late MockTicketRepository mockTicketRepo;

  setUpAll(() {
    registerFallbackValue(
      Ticket(
        id: '',
        name: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      TicketTemplate(
        id: '',
        name: '',
        partyId: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockTicketRepo = MockTicketRepository();

    when(() => mockTicketRepo.createTicket(any())).thenAnswer(
      (_) async => Ticket(
        id: 'ticket-new',
        name: 'ticket',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    when(() => mockTicketRepo.updateTicket(any())).thenAnswer(
      (_) async => Ticket(
        id: 'ticket-1',
        name: 'updated',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    when(() => mockTicketRepo.updateTicketTemplate(any())).thenAnswer(
      (_) async => TicketTemplate(
        id: 'tmpl-1',
        partyId: 'party-1',
        name: 'Template',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  ProviderContainer buildContainer() {
    return createContainer(
      overrides: [
        ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
      ],
    );
  }

  group('TicketController', () {
    test('initial state is AsyncData(null)', () {
      final container = buildContainer();
      final state = container.read(ticketControllerProvider);

      expect(state, isA<AsyncData>());
    });

    test('createTicket calls repo.createTicket and sets AsyncData', () async {
      final container = buildContainer();

      await container
          .read(ticketControllerProvider.notifier)
          .createTicket(
            eventId: 'event-1',
            name: 'VIP',
            price: 30000,
            quantity: 50,
          );

      verify(() => mockTicketRepo.createTicket(any())).called(1);

      final state = container.read(ticketControllerProvider);
      expect(state, isA<AsyncData>());
    });

    test('createTicket sets AsyncError on repo failure', () async {
      when(
        () => mockTicketRepo.createTicket(any()),
      ).thenThrow(Exception('create failed'));

      final container = buildContainer();

      await container
          .read(ticketControllerProvider.notifier)
          .createTicket(
            eventId: 'event-1',
            name: 'VIP',
            price: 30000,
            quantity: 50,
          );

      final state = container.read(ticketControllerProvider);
      expect(state, isA<AsyncError>());
    });

    test('updateTicket calls repo.updateTicket', () async {
      final container = buildContainer();

      final ticket = Ticket(
        id: 'ticket-1',
        name: 'General',
        eventId: 'event-1',
        price: 10000,
        quantity: 100,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await container
          .read(ticketControllerProvider.notifier)
          .updateTicket(ticket: ticket, name: 'General Updated');

      verify(() => mockTicketRepo.updateTicket(any())).called(1);
    });
  });
}
