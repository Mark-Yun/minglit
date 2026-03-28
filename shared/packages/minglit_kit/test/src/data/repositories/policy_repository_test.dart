import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/policy_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late PolicyRepository repository;

  setUp(() {
    mockClient = createMockSupabase();
    repository = PolicyRepository(mockClient);
  });

  group('PolicyRepository', () {
    group('getRefundPolicy', () {
      test('returns policy map when found', () async {
        final policyData = {
          'key': 'refund',
          'title': '환불 정책',
          'content': '결제 후 24시간 이내 환불 가능',
          'version': 1,
        };

        when(
          () => mockClient.rpc<Map<String, dynamic>?>(
            'get_current_policy',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder(policyData));

        final result = await repository.getRefundPolicy();

        expect(result, isNotNull);
        expect(result!['key'], 'refund');
        expect(result['title'], '환불 정책');
      });

      test('returns null when policy not found', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>?>(
            'get_current_policy',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder(null));

        final result = await repository.getRefundPolicy();

        expect(result, isNull);
      });

      test('throws on error', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>?>(
            'get_current_policy',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getRefundPolicy(),
          throwsA(anything),
        );
      });
    });
  });
}
