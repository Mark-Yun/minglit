import 'dart:async' show FutureOr;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/settlement_item_detail.dart';
import 'package:minglit_kit/src/data/repositories/settlement_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

/// Fake RPC result builder that resolves to [_data] when awaited.
class _FakeRpcResult<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpcResult(this._data);
  final T _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }
}

/// Minimal valid settlement item JSON for use in tests.
Map<String, dynamic> _settlementItemJson({String id = 'item_1'}) => {
      'id': id,
      'partner_id': 'partner_1',
      'event_id': null,
      'status': 'PENDING',
      'gross_amount': 10000,
      'platform_fee_amount': 500,
      'pg_fee_amount': 200,
      'vat_amount': 50,
      'net_amount': 9250,
      'currency': 'KRW',
      'hold_reason_code': null,
      'hold_reason_detail': null,
      'failure_reason_code': null,
      'failure_message': null,
      'settlement_period_start': null,
      'settlement_period_end': null,
      'processing_started_at': null,
      'processing_ended_at': null,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
      'payout_id': null,
      'retryable': false,
      'retry_count': 0,
    };

void main() {
  late MockSupabaseClient mockClient;
  late SettlementRepository repository;

  setUp(() {
    mockClient = createMockSupabase();
    repository = SettlementRepository(supabase: mockClient);
  });

  group('SettlementRepository', () {
    // -------------------------------------------------------------------------
    // getSettlementItems
    // -------------------------------------------------------------------------
    group('getSettlementItems', () {
      test('returns list of SettlementItemDetail', () async {
        await mockTable(
          mockClient,
          'settlement_items',
          selectData: [_settlementItemJson()],
        );

        final result = await repository.getSettlementItems(
          partnerId: 'partner_1',
        );

        expect(result, hasLength(1));
        expect(result.first, isA<SettlementItemDetail>());
        expect(result.first.id, 'item_1');
        expect(result.first.partnerId, 'partner_1');
      });

      test('returns empty list when no items', () async {
        await mockTable(mockClient, 'settlement_items', selectData: []);

        final result = await repository.getSettlementItems(
          partnerId: 'partner_1',
        );

        expect(result, isEmpty);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'settlement_items',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getSettlementItems(partnerId: 'partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getSettlementItemDetail
    // -------------------------------------------------------------------------
    group('getSettlementItemDetail', () {
      test('returns SettlementItemDetail with nested data', () async {
        final itemJson = _settlementItemJson();

        // settlement_items → maybeSingle returns the item
        await mockTable(
          mockClient,
          'settlement_items',
          maybeSingleData: itemJson,
        );
        // payouts → not queried because payout_id is null in itemJson
        // settlement_histories → returns empty list
        await mockTable(mockClient, 'settlement_histories', selectData: []);
        // adjustment_items → returns empty list
        await mockTable(mockClient, 'adjustment_items', selectData: []);

        final result = await repository.getSettlementItemDetail('item_1');

        expect(result, isNotNull);
        expect(result!.id, 'item_1');
        expect(result.histories, isEmpty);
        expect(result.adjustments, isEmpty);
      });

      test('returns null when item not found', () async {
        await mockTable(mockClient, 'settlement_items');
        // Other tables won't be queried when item is null.

        final result = await repository.getSettlementItemDetail('nonexistent');

        expect(result, isNull);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'settlement_items',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getSettlementItemDetail('item_1'),
          throwsA(isA<Exception>()),
        );
      });

      test('fetches payout info when payout_id is present', () async {
        final itemJsonWithPayout = {
          ..._settlementItemJson(),
          'payout_id': 'payout_1',
        };
        final payoutJson = {
          'id': 'payout_1',
          'status': 'COMPLETED',
          'scheduled_at': null,
          'total_net_amount': 9250,
          'bank_account_snapshot': null,
        };

        await mockTable(
          mockClient,
          'settlement_items',
          maybeSingleData: itemJsonWithPayout,
        );
        await mockTable(
          mockClient,
          'payouts',
          maybeSingleData: payoutJson,
        );
        await mockTable(mockClient, 'settlement_histories', selectData: []);
        await mockTable(mockClient, 'adjustment_items', selectData: []);

        final result = await repository.getSettlementItemDetail('item_1');

        expect(result, isNotNull);
        expect(result!.payoutId, 'payout_1');
        expect(result.payoutInfo, isNotNull);
        expect(result.payoutInfo!.id, 'payout_1');
        expect(result.payoutInfo!.status, 'COMPLETED');
      });
    });

    // -------------------------------------------------------------------------
    // getSettlementDashboard
    // -------------------------------------------------------------------------
    group('getSettlementDashboard', () {
      test('returns aggregated dashboard data', () async {
        await mockTable(
          mockClient,
          'settlement_items',
          selectData: [
            {
              'status': 'COMPLETED',
              'net_amount': 9000,
              'gross_amount': 10000,
            },
            {
              'status': 'COMPLETED',
              'net_amount': 8000,
              'gross_amount': 9000,
            },
            {
              'status': 'PENDING',
              'net_amount': 5000,
              'gross_amount': 6000,
            },
          ],
        );

        final result = await repository.getSettlementDashboard(
          partnerId: 'partner_1',
        );

        expect(result['total_items'], 3);
        final statusCounts = result['status_counts'] as Map<String, int>;
        expect(statusCounts['COMPLETED'], 2);
        expect(statusCounts['PENDING'], 1);
        expect(result['completed_net_total'], 17000);
        expect(result['completed_gross_total'], 19000);
      });

      test('returns zeros when no items', () async {
        await mockTable(mockClient, 'settlement_items', selectData: []);

        final result = await repository.getSettlementDashboard(
          partnerId: 'partner_1',
        );

        expect(result['total_items'], 0);
        expect(result['completed_net_total'], 0);
        expect(result['completed_gross_total'], 0);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'settlement_items',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getSettlementDashboard(partnerId: 'partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getEventInfo
    // -------------------------------------------------------------------------
    group('getEventInfo', () {
      test('returns event info map', () async {
        final eventJson = {
          'id': 'event_1',
          'title': '테스트 이벤트',
          'date': '2026-03-01',
          'parties': {'name': '테스트 파티'},
        };
        await mockTable(mockClient, 'events', maybeSingleData: eventJson);

        final result = await repository.getEventInfo('event_1');

        expect(result, isNotNull);
        expect(result!['id'], 'event_1');
        expect(result['title'], '테스트 이벤트');
      });

      test('returns null when event not found', () async {
        await mockTable(mockClient, 'events');

        final result = await repository.getEventInfo('nonexistent');

        expect(result, isNull);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'events',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getEventInfo('event_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getBankAccount
    // -------------------------------------------------------------------------
    group('getBankAccount', () {
      test('returns bank account map', () async {
        final bankJson = {
          'bank_name': '국민은행',
          'account_holder': '홍길동',
          'account_number': '123-456-789',
        };
        await mockTable(
          mockClient,
          'partner_settlements',
          maybeSingleData: bankJson,
        );

        final result = await repository.getBankAccount('partner_1');

        expect(result, isNotNull);
        expect(result!['bank_name'], '국민은행');
        expect(result['account_holder'], '홍길동');
      });

      test('returns null when not found', () async {
        await mockTable(mockClient, 'partner_settlements');

        final result = await repository.getBankAccount('partner_1');

        expect(result, isNull);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'partner_settlements',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getBankAccount('partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // upsertBankAccount
    // -------------------------------------------------------------------------
    group('upsertBankAccount', () {
      test('completes without error', () async {
        await mockTable(mockClient, 'partner_settlements');

        await expectLater(
          repository.upsertBankAccount(
            partnerId: 'partner_1',
            bankName: '국민은행',
            accountHolder: '홍길동',
            accountNumber: '123-456-789',
          ),
          completes,
        );
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'partner_settlements',
          shouldThrow: Exception('upsert failed'),
        );

        await expectLater(
          repository.upsertBankAccount(
            partnerId: 'partner_1',
            bankName: '국민은행',
            accountHolder: '홍길동',
            accountNumber: '123-456-789',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getPartnerSettlementInfo
    // -------------------------------------------------------------------------
    group('getPartnerSettlementInfo', () {
      test('returns partner settlement info map', () async {
        final infoJson = {
          'partner_id': 'partner_1',
          'bank_name': '신한은행',
          'account_holder': '김철수',
          'account_number': '987-654-321',
          'created_at': '2026-01-01T00:00:00.000Z',
        };
        await mockTable(
          mockClient,
          'partner_settlements',
          maybeSingleData: infoJson,
        );

        final result = await repository.getPartnerSettlementInfo('partner_1');

        expect(result, isNotNull);
        expect(result!['partner_id'], 'partner_1');
        expect(result['bank_name'], '신한은행');
      });

      test('returns null when not found', () async {
        await mockTable(mockClient, 'partner_settlements');

        final result = await repository.getPartnerSettlementInfo('partner_1');

        expect(result, isNull);
      });

      test('throws on db error', () async {
        await mockTable(
          mockClient,
          'partner_settlements',
          shouldThrow: Exception('db error'),
        );

        await expectLater(
          repository.getPartnerSettlementInfo('partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // retryPayout
    // -------------------------------------------------------------------------
    group('retryPayout', () {
      test('returns result map on success', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>>(
            'request_retry_payout',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => _FakeRpcResult<Map<String, dynamic>>({'status': 'ok'}),
        );

        final result = await repository.retryPayout(
          payoutId: 'payout_1',
          partnerId: 'partner_1',
        );

        expect(result['status'], 'ok');
      });

      test('throws on rpc error', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>>(
            'request_retry_payout',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('rpc error'));

        await expectLater(
          repository.retryPayout(
            payoutId: 'payout_1',
            partnerId: 'partner_1',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
