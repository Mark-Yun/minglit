import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/recurrence_rule.dart';
import 'package:minglit_kit/src/data/repositories/recurrence_rule_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late RecurrenceRuleRepository repository;

  final now = DateTime.utc(2026, 4, 5);

  final weeklyRuleJson = <String, dynamic>{
    'id': 'rule_1',
    'party_id': 'party_1',
    'pattern': 'weekly',
    'days_of_week': [1, 3, 5],
    'month_day': null,
    'start_time': '19:00:00',
    'end_time': '22:00:00',
    'end_date': null,
    'status': 'active',
    'last_generated_date': '2026-04-05',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = RecurrenceRuleRepository(mockClient);
  });

  group('RecurrenceRuleRepository', () {
    group('create', () {
      test('invokes EF with create action and returns rule', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({
              'success': true,
              'rule_id': 'rule_1',
              'events_created': 4,
            }),
          ),
        );

        mockTable(
          mockClient,
          'recurrence_rules',
          maybeSingleData: weeklyRuleJson,
        );

        final result = await repository.create(
          partyId: 'party_1',
          pattern: RecurrencePattern.weekly,
          daysOfWeek: [1, 3, 5],
          startTime: '19:00',
          endTime: '22:00',
        );

        expect(result.id, 'rule_1');
        expect(result.pattern, RecurrencePattern.weekly);
        expect(result.daysOfWeek, [1, 3, 5]);
        expect(result.status, RecurrenceStatus.active);

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'create');
        expect(body['party_id'], 'party_1');
        expect(body['pattern'], 'weekly');
        expect(body['days_of_week'], [1, 3, 5]);
      });

      test('includes optional fields when provided', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({
              'success': true,
              'rule_id': 'rule_2',
              'events_created': 1,
            }),
          ),
        );

        final monthlyJson = {
          ...weeklyRuleJson,
          'id': 'rule_2',
          'pattern': 'monthly',
          'days_of_week': <int>[],
          'month_day': 15,
        };
        mockTable(mockClient, 'recurrence_rules', maybeSingleData: monthlyJson);

        await repository.create(
          partyId: 'party_1',
          pattern: RecurrencePattern.monthly,
          daysOfWeek: [],
          monthDay: 15,
          startTime: '19:00',
          endTime: '22:00',
          endDate: '2026-12-31',
        );

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['month_day'], 15);
        expect(body['end_date'], '2026-12-31');
      });

      test('throws FunctionException on EF error', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({
              'error': 'days_of_week is required for weekly pattern',
            }),
          ),
        );

        expect(
          () => repository.create(
            partyId: 'party_1',
            pattern: RecurrencePattern.weekly,
            daysOfWeek: [],
            startTime: '19:00',
            endTime: '22:00',
          ),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('update', () {
      test('invokes EF with update action and rule_id', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await expectLater(
          repository.update('rule_1', startTime: '20:00', endTime: '23:00'),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'update');
        expect(body['rule_id'], 'rule_1');
        expect(body['start_time'], '20:00');
        expect(body['end_time'], '23:00');
      });

      test('only sends provided fields', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await repository.update('rule_1', daysOfWeek: [2, 4]);

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body.containsKey('pattern'), isFalse);
        expect(body['days_of_week'], [2, 4]);
      });

      test('throws on EF error', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({'error': 'Cannot update a cancelled rule'}),
          ),
        );

        expect(
          () => repository.update('rule_1', startTime: '20:00'),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('pause', () {
      test('invokes EF with pause action', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await expectLater(repository.pause('rule_1'), completes);

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'pause');
        expect(body['rule_id'], 'rule_1');
      });

      test('throws on EF error', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({'error': 'Rule is already paused'}),
          ),
        );

        expect(
          () => repository.pause('rule_1'),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('resume', () {
      test('invokes EF with resume action', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true, 'events_created': 2}),
          ),
        );

        await expectLater(repository.resume('rule_1'), completes);

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'resume');
        expect(body['rule_id'], 'rule_1');
      });
    });

    group('cancel', () {
      test('invokes EF with cancel action', () async {
        when(
          () => mockFunctions.invoke(_efName, body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await expectLater(repository.cancel('rule_1'), completes);

        final captured = verify(
          () => mockFunctions.invoke(_efName, body: captureAny(named: 'body')),
        ).captured;
        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'cancel');
        expect(body['rule_id'], 'rule_1');
      });
    });

    group('getByPartyId', () {
      test('returns rule when active rule exists', () async {
        mockTable(
          mockClient,
          'recurrence_rules',
          maybeSingleData: weeklyRuleJson,
        );

        final result = await repository.getByPartyId('party_1');

        expect(result, isNotNull);
        expect(result!.id, 'rule_1');
        expect(result.partyId, 'party_1');
        expect(result.pattern, RecurrencePattern.weekly);
        expect(result.daysOfWeek, [1, 3, 5]);
      });

      test('returns null when no active rule exists', () async {
        mockTable(mockClient, 'recurrence_rules');

        final result = await repository.getByPartyId('party_unknown');

        expect(result, isNull);
      });
    });

    group('getById', () {
      test('returns rule when found', () async {
        mockTable(
          mockClient,
          'recurrence_rules',
          maybeSingleData: weeklyRuleJson,
        );

        final result = await repository.getById('rule_1');

        expect(result, isNotNull);
        expect(result!.id, 'rule_1');
      });

      test('returns null when not found', () async {
        mockTable(mockClient, 'recurrence_rules');

        final result = await repository.getById('nonexistent');

        expect(result, isNull);
      });
    });
  });
}

const _efName = 'recurrence-rules';
