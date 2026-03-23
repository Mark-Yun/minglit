import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late PartyRepository repository;
  late MockFunctionsClient mockFunctions;

  final now = DateTime.now();

  final partyJson = {
    'id': 'party_1',
    'partner_id': 'partner_1',
    'title': '테스트 파티',
    'status': 'active',
    'visibility': 'public',
    'max_participants': 10,
    'min_confirmed_count': 0,
    'image_urls': <String>[],
    'contact_options': <String, dynamic>{},
    'metadata': <String, dynamic>{},
    'required_verification_ids': <String>[],
    'location_id': null,
    'description': null,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = PartyRepository(supabase: mockClient);
  });

  group('PartyRepository', () {
    group('getPartyById', () {
      test('returns party when found', () async {
        unawaited(
          mockTable(mockClient, 'parties', maybeSingleData: partyJson),
        );

        final result = await repository.getPartyById('party_1');

        expect(result, isNotNull);
        expect(result!.id, 'party_1');
        expect(result.partnerId, 'partner_1');
      });

      test('returns null when not found', () async {
        unawaited(mockTable(mockClient, 'parties'));

        final result = await repository.getPartyById('unknown');

        expect(result, isNull);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'parties', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.getPartyById('party_1'),
          throwsA(anything),
        );
      });
    });

    group('getPartiesByPartnerId', () {
      test('returns list of parties', () async {
        unawaited(
          mockTable(mockClient, 'parties', selectData: [partyJson]),
        );

        final result = await repository.getPartiesByPartnerId('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'party_1');
      });

      test('returns empty list when no parties', () async {
        unawaited(mockTable(mockClient, 'parties', selectData: []));

        final result = await repository.getPartiesByPartnerId('partner_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'parties', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.getPartiesByPartnerId('partner_1'),
          throwsA(anything),
        );
      });
    });

    group('getParties', () {
      test('returns all parties', () async {
        unawaited(
          mockTable(mockClient, 'parties', selectData: [partyJson]),
        );

        final result = await repository.getParties();

        expect(result, hasLength(1));
        expect(result.first.id, 'party_1');
      });

      test('returns empty list when no parties', () async {
        unawaited(mockTable(mockClient, 'parties', selectData: []));

        final result = await repository.getParties();

        expect(result, isEmpty);
      });
    });

    // Fix #316: createParty now uses EF invoke
    group('createParty', () {
      test('returns created party on success', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true, 'party_id': 'party_1'},
          ),
        );
        // Mock getPartyById (called after EF create)
        unawaited(
          mockTable(
            mockClient,
            'parties',
            maybeSingleData: partyJson,
          ),
        );

        final party = Party.fromJson(partyJson);
        final result = await repository.createParty(party);

        expect(result.id, 'party_1');
        expect(result.partnerId, 'partner_1');
      });

      test('throws on error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 403,
            data: {'error': 'Forbidden'},
          ),
        );

        final party = Party.fromJson(partyJson);
        await expectLater(
          repository.createParty(party),
          throwsA(anything),
        );
      });
    });

    // Fix #316: updateParty now uses EF invoke
    group('updateParty', () {
      test('returns updated party on success', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );
        // Mock getPartyById (called after EF update)
        unawaited(
          mockTable(
            mockClient,
            'parties',
            maybeSingleData: partyJson,
          ),
        );

        final party = Party.fromJson(partyJson);
        final result = await repository.updateParty(party);

        expect(result.id, 'party_1');
      });

      test('throws on error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 500,
            data: {'error': 'Failed'},
          ),
        );

        final party = Party.fromJson(partyJson);
        await expectLater(
          repository.updateParty(party),
          throwsA(anything),
        );
      });
    });

    // Fix #316: updatePartyStatus now uses EF invoke
    group('updatePartyStatus', () {
      test('completes without error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        await expectLater(
          repository.updatePartyStatus('party_1', 'closed'),
          completes,
        );
      });

      test('throws on error', () async {
        when(
          () => mockFunctions.invoke(
            'partner-manage-party',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: {'error': 'Invalid status'},
          ),
        );

        await expectLater(
          repository.updatePartyStatus('party_1', 'closed'),
          throwsA(anything),
        );
      });
    });
  });

  group('PartyRepository (events)', () {
    final eventJson = {
      'id': 'event_1',
      'party_id': 'party_1',
      'title': '테스트 이벤트',
      'status': 'upcoming',
      'visibility': 'public',
      'max_participants': 10,
      'min_confirmed_count': 0,
      'current_participants': 0,
      'start_time': now.toIso8601String(),
      'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    group('getEventsByPartyId', () {
      test('returns list of events', () async {
        unawaited(mockTable(mockClient, 'events', selectData: [eventJson]));

        final result = await repository.getEventsByPartyId('party_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      test('returns empty list when no events', () async {
        unawaited(mockTable(mockClient, 'events', selectData: []));

        final result = await repository.getEventsByPartyId('party_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.getEventsByPartyId('party_1'),
          throwsA(anything),
        );
      });
    });

    group('createEvent', () {
      test('returns created event on success', () async {
        unawaited(mockTable(mockClient, 'events', singleData: eventJson));

        final event = Event.fromJson(eventJson);
        final result = await repository.createEvent(event);

        expect(result.id, 'event_1');
        expect(result.partyId, 'party_1');
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        final event = Event.fromJson(eventJson);
        await expectLater(
          repository.createEvent(event),
          throwsA(anything),
        );
      });
    });

    group('updateEvent', () {
      test('returns updated event on success', () async {
        unawaited(mockTable(mockClient, 'events', singleData: eventJson));

        final event = Event.fromJson(eventJson);
        final result = await repository.updateEvent(event);

        expect(result.id, 'event_1');
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        final event = Event.fromJson(eventJson);
        await expectLater(
          repository.updateEvent(event),
          throwsA(anything),
        );
      });
    });

    group('updateEventStatus', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'events'));

        await expectLater(
          repository.updateEventStatus('event_1', 'active'),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.updateEventStatus('event_1', 'active'),
          throwsA(anything),
        );
      });
    });

    group('updateEventMetadata', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'events'));

        await expectLater(
          repository.updateEventMetadata(
            'event_1',
            {'theme': 'dark', 'capacity': 50},
          ),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.updateEventMetadata('event_1', {'key': 'value'}),
          throwsA(anything),
        );
      });
    });
  });

  group('PartyRepository (matching)', () {
    group('replaceEntryGroupTemplates', () {
      test('completes with empty templates (delete only)', () async {
        unawaited(mockTable(mockClient, 'entry_groups'));

        await expectLater(
          repository.replaceEntryGroupTemplates('party_1', []),
          completes,
        );
      });

      test('completes with templates (delete + insert)', () async {
        unawaited(mockTable(mockClient, 'entry_groups'));

        final templates = [
          const EntryGroupTemplate(
            id: 'eg_1',
            partyId: 'party_1',
            label: '남성',
            gender: 'male',
            birthYearMin: 1990,
            birthYearMax: 2000,
          ),
        ];

        await expectLater(
          repository.replaceEntryGroupTemplates('party_1', templates),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'entry_groups',
            shouldThrow: Exception('error'),
          ),
        );

        await expectLater(
          repository.replaceEntryGroupTemplates('party_1', []),
          throwsA(anything),
        );
      });
    });
  });
}
