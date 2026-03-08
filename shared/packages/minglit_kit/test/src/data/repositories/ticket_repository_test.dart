import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/ticket.dart';
import 'package:minglit_kit/src/data/models/ticket_template.dart';
import 'package:minglit_kit/src/data/repositories/ticket_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late TicketRepository repository;

  final now = DateTime.now();
  final ticketJson = {
    'id': 'ticket_1',
    'name': '일반 티켓',
    'event_id': 'event_1',
    'price': 30000,
    'quantity': 100,
    'sold_count': 10,
    'status': 'on_sale',
    'target_entry_group_ids': <String>[],
    'required_verification_ids': <String>[],
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  final templateJson = {
    'id': 'template_1',
    'party_id': 'party_1',
    'name': '기본 템플릿',
    'price': 25000,
    'quantity': 50,
    'target_entry_group_ids': <String>[],
    'required_verification_ids': <String>[],
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase();
    repository = TicketRepository(supabase: mockClient);
  });

  group('TicketRepository', () {
    group('getTicketsByEventId', () {
      test('returns list of tickets for event', () async {
        unawaited(
          mockTable(
            mockClient,
            'tickets',
            selectData: [ticketJson],
          ),
        );

        final result = await repository.getTicketsByEventId('event_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'ticket_1');
        expect(result.first.name, '일반 티켓');
        expect(result.first.price, 30000);
      });

      test('returns empty list when no tickets', () async {
        unawaited(mockTable(mockClient, 'tickets', selectData: []));

        final result = await repository.getTicketsByEventId('event_none');
        expect(result, isEmpty);
      });
    });

    group('getTicketsByPartyId', () {
      test('returns tickets for party', () async {
        unawaited(mockTable(mockClient, 'tickets', selectData: [ticketJson]));

        final result = await repository.getTicketsByPartyId('party_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'ticket_1');
      });
    });

    group('getTicketTemplatesByPartyId', () {
      test('returns templates for party', () async {
        unawaited(
          mockTable(
            mockClient,
            'ticket_templates',
            selectData: [templateJson],
          ),
        );

        final result = await repository.getTicketTemplatesByPartyId('party_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'template_1');
        expect(result.first.name, '기본 템플릿');
        expect(result.first.price, 25000);
      });
    });

    group('getDefaultTicketsByPartyId', () {
      test('aliases getTicketTemplatesByPartyId', () async {
        unawaited(
          mockTable(
            mockClient,
            'ticket_templates',
            selectData: [templateJson],
          ),
        );

        final result = await repository.getDefaultTicketsByPartyId('party_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'template_1');
      });
    });

    group('getTicketById', () {
      test('returns ticket by ID', () async {
        unawaited(mockTable(mockClient, 'tickets', singleData: ticketJson));

        final result = await repository.getTicketById('ticket_1');

        expect(result.id, 'ticket_1');
        expect(result.name, '일반 티켓');
        expect(result.soldCount, 10);
      });
    });

    group('getTicketTemplateById', () {
      test('returns template by ID', () async {
        unawaited(
          mockTable(mockClient, 'ticket_templates', singleData: templateJson),
        );

        final result = await repository.getTicketTemplateById('template_1');

        expect(result.id, 'template_1');
        expect(result.partyId, 'party_1');
      });
    });

    group('createTicket', () {
      test('creates and returns new ticket', () async {
        unawaited(
          mockTable(
            mockClient,
            'tickets',
            selectData: [ticketJson],
            singleData: ticketJson,
            insertReturnData: ticketJson,
          ),
        );

        final ticket = Ticket.fromJson(ticketJson);
        final result = await repository.createTicket(ticket);

        expect(result.id, 'ticket_1');
        expect(result.name, '일반 티켓');
      });
    });

    group('createTicketTemplate', () {
      test('creates and returns new template', () async {
        unawaited(
          mockTable(
            mockClient,
            'ticket_templates',
            selectData: [templateJson],
            singleData: templateJson,
            insertReturnData: templateJson,
          ),
        );

        final template = TicketTemplate.fromJson(templateJson);
        final result = await repository.createTicketTemplate(template);

        expect(result.id, 'template_1');
        expect(result.name, '기본 템플릿');
      });
    });

    group('updateTicket', () {
      test('throws MinglitUserException when quantity < sold_count', () async {
        // getTicketById returns ticket with soldCount=10
        unawaited(mockTable(mockClient, 'tickets', singleData: ticketJson));

        // Create a ticket with quantity less than sold count
        final ticket = (await repository.getTicketById(
          'ticket_1',
        )).copyWith(quantity: 5); // 5 < 10 (soldCount)

        // Re-setup for the update call's getTicketById
        unawaited(mockTable(mockClient, 'tickets', singleData: ticketJson));

        expect(
          () => repository.updateTicket(ticket),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('succeeds when quantity >= sold_count', () async {
        final updatedJson = {
          ...ticketJson,
          'quantity': 200,
        };

        // First call: getTicketById (inside updateTicket)
        unawaited(mockTable(mockClient, 'tickets', singleData: ticketJson));

        final ticket = (await repository.getTicketById(
          'ticket_1',
        )).copyWith(quantity: 200); // 200 >= 10 (soldCount)

        // Re-setup: getTicketById + update chain
        unawaited(mockTable(mockClient, 'tickets', singleData: updatedJson));

        final result = await repository.updateTicket(ticket);
        expect(result.quantity, 200);
      });
    });

    group('updateTicketTemplate', () {
      test('updates and returns template', () async {
        unawaited(
          mockTable(mockClient, 'ticket_templates', singleData: templateJson),
        );

        final template = await repository.getTicketTemplateById('template_1');

        final updatedJson = {...templateJson, 'name': '업데이트된 템플릿'};
        unawaited(
          mockTable(
            mockClient,
            'ticket_templates',
            singleData: updatedJson,
          ),
        );

        final result = await repository.updateTicketTemplate(
          template.copyWith(name: '업데이트된 템플릿'),
        );
        expect(result.name, '업데이트된 템플릿');
      });
    });

    group('deleteTicketTemplate', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'ticket_templates'));

        await expectLater(
          repository.deleteTicketTemplate('template_1'),
          completes,
        );
      });
    });
  });
}
