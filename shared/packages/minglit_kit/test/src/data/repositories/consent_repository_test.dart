import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_consent.dart';
import 'package:minglit_kit/src/data/repositories/consent_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late ConsentRepository repository;

  final now = DateTime.now();

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = ConsentRepository(mockClient);
  });

  group('ConsentRepository', () {
    group('getConsents', () {
      test('returns list of active consents', () async {
        final consentJson = {
          'id': 'c1',
          'user_id': 'user_1',
          'consent_key': 'terms_of_service',
          'consented': true,
          'policy_version': 1,
          'consented_at': now.toIso8601String(),
          'withdrawn_at': null,
          'created_at': now.toIso8601String(),
        };

        mockTable(mockClient, 'user_consents', selectData: [consentJson]);

        final result = await repository.getConsents('user_1');

        expect(result, hasLength(1));
        expect(result.first.consentKey, ConsentType.termsOfService);
        expect(result.first.consented, true);
        expect(result.first.userId, 'user_1');
      });

      test('throws on error', () async {
        mockTable(
          mockClient,
          'user_consents',
          shouldThrow: Exception('DB error'),
        );

        expect(
          () => repository.getConsents('user_1'),
          throwsA(isA<Exception>()),
        );
      });

      test('returns empty list when no consents', () async {
        mockTable(mockClient, 'user_consents');

        final result = await repository.getConsents('user_1');

        expect(result, isEmpty);
      });
    });

    group('saveConsents', () {
      test('calls user-manage-settings EF with correct body', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {'success': true},
          ),
        );

        await repository.saveConsents('user_1', [
          const ConsentInput(
            consentKey: ConsentType.termsOfService,
            consented: true,
            policyVersion: 1,
          ),
          const ConsentInput(
            consentKey: ConsentType.privacyCollection,
            consented: true,
            policyVersion: 1,
          ),
        ]);

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'save_consents');
        expect(body['user_id'], 'user_1');
        expect(body['consents'], isList);
        expect(body['consents'] as List, hasLength(2));
      });

      test('throws on EF error', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 500,
            data: {'error': 'EF error'},
          ),
        );

        expect(
          () => repository.saveConsents('user_1', [
            const ConsentInput(
              consentKey: ConsentType.termsOfService,
              consented: true,
            ),
          ]),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('hasRequiredConsents', () {
      test('returns true when all required consents exist', () async {
        when(
          () => mockClient.rpc<bool>('has_required_consents'),
        ).thenAnswer((_) => FakeRpcBuilder(true));

        final result = await repository.hasRequiredConsents();

        expect(result, true);
      });

      test('returns false when missing consents', () async {
        when(
          () => mockClient.rpc<bool>('has_required_consents'),
        ).thenAnswer((_) => FakeRpcBuilder(false));

        final result = await repository.hasRequiredConsents();

        expect(result, false);
      });

      test('throws on error', () async {
        when(
          () => mockClient.rpc<bool>('has_required_consents'),
        ).thenThrow(Exception('RPC error'));

        expect(
          () => repository.hasRequiredConsents(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
