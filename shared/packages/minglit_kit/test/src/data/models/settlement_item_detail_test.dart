// Fix #1103: settlement 도메인 테스트 보강

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/settlement_item_detail.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helper data builders
  // ---------------------------------------------------------------------------
  Map<String, dynamic> baseItemJson() => {
    'id': 'item-1',
    'partner_id': 'partner-1',
    'status': 'COMPLETED',
    'gross_amount': 100000,
    'platform_fee_amount': 5000,
    'pg_fee_amount': 1500,
    'vat_amount': 500,
    'net_amount': 93000,
    'currency': 'KRW',
    'created_at': '2026-01-15T10:00:00.000Z',
    'updated_at': '2026-01-16T12:00:00.000Z',
    'retryable': false,
    'retry_count': 0,
  };

  // ---------------------------------------------------------------------------
  // PayoutSummary
  // ---------------------------------------------------------------------------
  group('PayoutSummary.fromJson', () {
    test('parses all fields', () {
      final result = PayoutSummary.fromJson({
        'id': 'payout-1',
        'status': 'COMPLETED',
        'total_net_amount': 93000,
        'scheduled_at': '2026-01-20T09:00:00.000Z',
        'bank_account_snapshot': {'bank': 'KB', 'account_number': '1234'},
      });
      expect(result.id, 'payout-1');
      expect(result.status, 'COMPLETED');
      expect(result.totalNetAmount, 93000);
      expect(result.scheduledAt, isA<DateTime>());
      expect(result.scheduledAt!.year, 2026);
      expect(result.bankAccountSnapshot, isNotNull);
      expect(result.bankAccountSnapshot!['bank'], 'KB');
    });

    test('scheduledAt is null when not provided', () {
      final result = PayoutSummary.fromJson({
        'id': 'payout-1',
        'status': 'CREATED',
        'total_net_amount': 0,
        'scheduled_at': null,
      });
      expect(result.scheduledAt, isNull);
    });

    test('bankAccountSnapshot is null when not provided', () {
      final result = PayoutSummary.fromJson({
        'id': 'payout-1',
        'status': 'CREATED',
        'total_net_amount': 0,
      });
      expect(result.bankAccountSnapshot, isNull);
    });

    test('round-trip toJson/fromJson', () {
      final original = PayoutSummary.fromJson({
        'id': 'payout-1',
        'status': 'COMPLETED',
        'total_net_amount': 93000,
        'scheduled_at': '2026-01-20T09:00:00.000Z',
        'bank_account_snapshot': {'bank': 'KB'},
      });
      final json = original.toJson();
      final restored = PayoutSummary.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.totalNetAmount, original.totalNetAmount);
      expect(restored.scheduledAt, original.scheduledAt);
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementHistoryEntry
  // ---------------------------------------------------------------------------
  group('SettlementHistoryEntry.fromJson', () {
    test('parses all fields', () {
      final result = SettlementHistoryEntry.fromJson({
        'event_type': 'STATUS_CHANGED',
        'from_status': 'PENDING',
        'to_status': 'READY',
        'created_at': '2026-01-15T10:00:00.000Z',
        'details': {'reason': 'auto-confirmed'},
      });
      expect(result.eventType, 'STATUS_CHANGED');
      expect(result.fromStatus, 'PENDING');
      expect(result.toStatus, 'READY');
      expect(result.createdAt, isA<DateTime>());
      expect(result.createdAt.year, 2026);
      expect(result.details, isNotNull);
      expect(result.details!['reason'], 'auto-confirmed');
    });

    test('details is null when not provided', () {
      final result = SettlementHistoryEntry.fromJson({
        'event_type': 'STATUS_CHANGED',
        'from_status': 'PENDING',
        'to_status': 'READY',
        'created_at': '2026-01-15T10:00:00.000Z',
      });
      expect(result.details, isNull);
    });

    test('round-trip toJson/fromJson', () {
      final original = SettlementHistoryEntry.fromJson({
        'event_type': 'STATUS_CHANGED',
        'from_status': 'PENDING',
        'to_status': 'COMPLETED',
        'created_at': '2026-01-15T10:00:00.000Z',
      });
      final json = original.toJson();
      final restored = SettlementHistoryEntry.fromJson(json);
      expect(restored.eventType, original.eventType);
      expect(restored.fromStatus, original.fromStatus);
      expect(restored.toStatus, original.toStatus);
      expect(restored.createdAt, original.createdAt);
    });
  });

  // ---------------------------------------------------------------------------
  // AdjustmentItemModel
  // ---------------------------------------------------------------------------
  group('AdjustmentItemModel.fromJson', () {
    test('parses all fields', () {
      final result = AdjustmentItemModel.fromJson({
        'id': 'adj-1',
        'adjustment_type': 'REFUND',
        'amount_signed': -5000,
        'status': 'APPLIED',
        'reason_code': 'CUSTOMER_CANCEL',
      });
      expect(result.id, 'adj-1');
      expect(result.adjustmentType, 'REFUND');
      expect(result.amountSigned, -5000);
      expect(result.status, 'APPLIED');
      expect(result.reasonCode, 'CUSTOMER_CANCEL');
    });

    test('reasonCode is null when not provided', () {
      final result = AdjustmentItemModel.fromJson({
        'id': 'adj-1',
        'adjustment_type': 'BONUS',
        'amount_signed': 1000,
        'status': 'APPLIED',
      });
      expect(result.reasonCode, isNull);
    });

    test('round-trip toJson/fromJson', () {
      final original = AdjustmentItemModel.fromJson({
        'id': 'adj-1',
        'adjustment_type': 'PENALTY',
        'amount_signed': -2000,
        'status': 'PENDING',
        'reason_code': 'LATE_CANCEL',
      });
      final json = original.toJson();
      final restored = AdjustmentItemModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.adjustmentType, original.adjustmentType);
      expect(restored.amountSigned, original.amountSigned);
      expect(restored.status, original.status);
      expect(restored.reasonCode, original.reasonCode);
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementItemDetail
  // ---------------------------------------------------------------------------
  group('SettlementItemDetail.fromJson', () {
    test('parses all required fields', () {
      final result = SettlementItemDetail.fromJson(baseItemJson());
      expect(result.id, 'item-1');
      expect(result.partnerId, 'partner-1');
      expect(result.status, 'COMPLETED');
      expect(result.grossAmount, 100000);
      expect(result.platformFeeAmount, 5000);
      expect(result.pgFeeAmount, 1500);
      expect(result.vatAmount, 500);
      expect(result.netAmount, 93000);
      expect(result.currency, 'KRW');
      expect(result.retryable, isFalse);
      expect(result.retryCount, 0);
      expect(result.createdAt, isA<DateTime>());
      expect(result.updatedAt, isA<DateTime>());
    });

    test('optional fields default to null when absent', () {
      final result = SettlementItemDetail.fromJson(baseItemJson());
      expect(result.eventId, isNull);
      expect(result.holdReasonCode, isNull);
      expect(result.holdReasonDetail, isNull);
      expect(result.failureReasonCode, isNull);
      expect(result.failureMessage, isNull);
      expect(result.settlementPeriodStart, isNull);
      expect(result.settlementPeriodEnd, isNull);
      expect(result.processingStartedAt, isNull);
      expect(result.processingEndedAt, isNull);
      expect(result.payoutId, isNull);
      expect(result.payoutInfo, isNull);
    });

    test('parses optional datetime fields', () {
      final result = SettlementItemDetail.fromJson({
        ...baseItemJson(),
        'settlement_period_start': '2026-01-01T00:00:00.000Z',
        'settlement_period_end': '2026-01-31T23:59:59.000Z',
        'processing_started_at': '2026-01-20T09:00:00.000Z',
        'processing_ended_at': '2026-01-20T09:05:00.000Z',
        'payout_id': 'payout-1',
        'event_id': 'evt-1',
      });
      expect(result.settlementPeriodStart, isA<DateTime>());
      expect(result.settlementPeriodEnd, isA<DateTime>());
      expect(result.processingStartedAt, isA<DateTime>());
      expect(result.processingEndedAt, isA<DateTime>());
      expect(result.payoutId, 'payout-1');
      expect(result.eventId, 'evt-1');
    });

    test('histories and adjustments default to empty list', () {
      final result = SettlementItemDetail.fromJson(baseItemJson());
      expect(result.histories, isEmpty);
      expect(result.adjustments, isEmpty);
    });

    test('populates nested payout from payoutData', () {
      final result = SettlementItemDetail.fromJson(
        baseItemJson(),
        payoutData: {
          'id': 'payout-1',
          'status': 'COMPLETED',
          'total_net_amount': 93000,
          'scheduled_at': null,
        },
      );
      expect(result.payoutInfo, isNotNull);
      expect(result.payoutInfo!.id, 'payout-1');
    });

    test('populates nested histories from historiesData', () {
      final result = SettlementItemDetail.fromJson(
        baseItemJson(),
        historiesData: [
          {
            'event_type': 'STATUS_CHANGED',
            'from_status': 'PENDING',
            'to_status': 'READY',
            'created_at': '2026-01-15T10:00:00.000Z',
          },
          {
            'event_type': 'STATUS_CHANGED',
            'from_status': 'READY',
            'to_status': 'COMPLETED',
            'created_at': '2026-01-20T09:05:00.000Z',
          },
        ],
      );
      expect(result.histories.length, 2);
      expect(result.histories.first.fromStatus, 'PENDING');
      expect(result.histories.last.toStatus, 'COMPLETED');
    });

    test('populates nested adjustments from adjustmentsData', () {
      final result = SettlementItemDetail.fromJson(
        baseItemJson(),
        adjustmentsData: [
          {
            'id': 'adj-1',
            'adjustment_type': 'REFUND',
            'amount_signed': -5000,
            'status': 'APPLIED',
          },
        ],
      );
      expect(result.adjustments.length, 1);
      expect(result.adjustments.first.id, 'adj-1');
    });

    test('retryable defaults to false when null', () {
      final result = SettlementItemDetail.fromJson({
        ...baseItemJson(),
        'retryable': null,
      });
      expect(result.retryable, isFalse);
    });

    test('retryCount defaults to 0 when null', () {
      final result = SettlementItemDetail.fromJson({
        ...baseItemJson(),
        'retry_count': null,
      });
      expect(result.retryCount, 0);
    });

    test('toJson round-trip preserves all flat fields', () {
      final original = SettlementItemDetail.fromJson({
        ...baseItemJson(),
        'event_id': 'evt-1',
        'hold_reason_code': 'VERIFICATION_REQUIRED',
        'settlement_period_start': '2026-01-01T00:00:00.000Z',
        'settlement_period_end': '2026-01-31T00:00:00.000Z',
        'payout_id': 'payout-1',
        'retryable': true,
        'retry_count': 2,
      });
      final json = original.toJson();

      expect(json['id'], 'item-1');
      expect(json['partner_id'], 'partner-1');
      expect(json['event_id'], 'evt-1');
      expect(json['status'], 'COMPLETED');
      expect(json['gross_amount'], 100000);
      expect(json['platform_fee_amount'], 5000);
      expect(json['pg_fee_amount'], 1500);
      expect(json['vat_amount'], 500);
      expect(json['net_amount'], 93000);
      expect(json['currency'], 'KRW');
      expect(json['hold_reason_code'], 'VERIFICATION_REQUIRED');
      expect(json['payout_id'], 'payout-1');
      expect(json['retryable'], isTrue);
      expect(json['retry_count'], 2);
      expect(json['settlement_period_start'], isA<String>());
      expect(json['settlement_period_end'], isA<String>());
    });

    test('toJson null fields remain null', () {
      final result = SettlementItemDetail.fromJson(baseItemJson());
      final json = result.toJson();
      expect(json['event_id'], isNull);
      expect(json['hold_reason_code'], isNull);
      expect(json['payout_id'], isNull);
      expect(json['settlement_period_start'], isNull);
    });
  });
}
