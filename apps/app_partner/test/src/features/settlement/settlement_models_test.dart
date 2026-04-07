// Fix #1103: settlement 도메인 테스트 보강

import 'package:app_partner/src/features/settlement/settlement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PartnerRevenueSummary
  // ---------------------------------------------------------------------------
  group('PartnerRevenueSummary.fromJson', () {
    test('parses int values', () {
      final result = PartnerRevenueSummary.fromJson({
        'total_sales': 100000,
        'total_refunds': 5000,
        'net_amount': 95000,
      });
      expect(result.totalSales, 100000);
      expect(result.totalRefunds, 5000);
      expect(result.netAmount, 95000);
    });

    test('parses numeric (double) values via _toInt', () {
      final result = PartnerRevenueSummary.fromJson({
        'total_sales': 100000.7,
        'total_refunds': 5000.3,
        'net_amount': 95000.5,
      });
      expect(result.totalSales, 100001); // rounds
      expect(result.totalRefunds, 5000); // rounds down
    });

    test('parses string values via _toInt', () {
      final result = PartnerRevenueSummary.fromJson({
        'total_sales': '100000',
        'total_refunds': '5000',
        'net_amount': '95000',
      });
      expect(result.totalSales, 100000);
      expect(result.totalRefunds, 5000);
      expect(result.netAmount, 95000);
    });

    test('defaults to 0 when fields are null', () {
      final result = PartnerRevenueSummary.fromJson({});
      expect(result.totalSales, 0);
      expect(result.totalRefunds, 0);
      expect(result.netAmount, 0);
    });

    test('defaults to 0 when fields are invalid string', () {
      final result = PartnerRevenueSummary.fromJson({
        'total_sales': 'invalid',
        'total_refunds': null,
        'net_amount': '',
      });
      expect(result.totalSales, 0);
      expect(result.totalRefunds, 0);
      expect(result.netAmount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // PartnerMonthlyRevenue
  // ---------------------------------------------------------------------------
  group('PartnerMonthlyRevenue.fromJson', () {
    test('parses all fields correctly', () {
      final result = PartnerMonthlyRevenue.fromJson({
        'month': '2026-01-01T00:00:00.000Z',
        'total_sales': 50000,
        'total_refunds': 2000,
        'net_amount': 48000,
      });
      expect(result.totalSales, 50000);
      expect(result.totalRefunds, 2000);
      expect(result.netAmount, 48000);
      expect(result.month, isA<DateTime>());
      expect(result.month.year, 2026);
      expect(result.month.month, 1);
    });

    test('parses date-only string for month', () {
      final result = PartnerMonthlyRevenue.fromJson({
        'month': '2026-03-01',
        'total_sales': 0,
        'total_refunds': 0,
        'net_amount': 0,
      });
      expect(result.month.year, 2026);
      expect(result.month.month, 3);
    });

    test('defaults numeric fields to 0 when missing', () {
      final result = PartnerMonthlyRevenue.fromJson({'month': '2026-01-01'});
      expect(result.totalSales, 0);
      expect(result.totalRefunds, 0);
      expect(result.netAmount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // PartnerSettlement
  // ---------------------------------------------------------------------------
  group('PartnerSettlement.fromJson', () {
    Map<String, dynamic> sampleJson() => {
      'id': 'settle-1',
      'event_id': 'evt-1',
      'event_title': 'Test Event',
      'event_date': '2026-01-15T10:00:00.000Z',
      'total_sales': 50000,
      'total_refunds': 2000,
      'pg_fee': 500,
      'platform_fee': 1000,
      'vat': 100,
      'net_amount': 46400,
      'status': 'COMPLETED',
    };

    test('parses all fields correctly', () {
      final result = PartnerSettlement.fromJson(sampleJson());
      expect(result.id, 'settle-1');
      expect(result.eventId, 'evt-1');
      expect(result.eventTitle, 'Test Event');
      expect(result.totalSales, 50000);
      expect(result.totalRefunds, 2000);
      expect(result.pgFee, 500);
      expect(result.platformFee, 1000);
      expect(result.vat, 100);
      expect(result.netAmount, 46400);
    });

    test('normalizes UPPERCASE status to lowercase', () {
      final result = PartnerSettlement.fromJson(sampleJson());
      expect(result.status, 'completed');
    });

    test('normalizes various statuses to lowercase', () {
      for (final status in [
        'PENDING',
        'HOLD',
        'READY',
        'PROCESSING',
        'FAILED',
        'CANCELED',
      ]) {
        final result = PartnerSettlement.fromJson({
          ...sampleJson(),
          'status': status,
        });
        expect(result.status, status.toLowerCase());
      }
    });

    test('defaults string fields to empty string when null', () {
      final result = PartnerSettlement.fromJson({
        'id': null,
        'event_id': null,
        'event_title': null,
        'event_date': '2026-01-15',
        'total_sales': 0,
        'total_refunds': 0,
        'pg_fee': 0,
        'platform_fee': 0,
        'vat': 0,
        'net_amount': 0,
        'status': null,
      });
      expect(result.id, '');
      expect(result.eventId, '');
      expect(result.eventTitle, '');
      expect(result.status, 'pending');
    });

    test('parses event_date as DateTime', () {
      final result = PartnerSettlement.fromJson(sampleJson());
      expect(result.eventDate, isA<DateTime>());
      expect(result.eventDate.year, 2026);
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementItem
  // ---------------------------------------------------------------------------
  group('SettlementItem.fromJson', () {
    Map<String, dynamic> fullJson() => {
      'id': 'item-1',
      'partner_id': 'partner-1',
      'settlement_period_start': '2026-01-01',
      'settlement_period_end': '2026-01-31',
      'currency': 'KRW',
      'source_type': 'EVENT',
      'source_id': 'evt-1',
      'status': 'COMPLETED',
      'gross_amount': 100000,
      'platform_fee_rate': 0.05,
      'platform_fee_amount': 5000,
      'pg_fee_rate': 0.015,
      'pg_fee_amount': 1500,
      'vat_rate': 0.1,
      'vat_amount': 500,
      'net_amount': 93000,
      'retryable': false,
      'retry_count': 0,
      'calc_checksum': 'abc123',
      'version': 1,
      'created_at': '2026-01-15T10:00:00.000Z',
      'updated_at': '2026-01-16T12:00:00.000Z',
    };

    test('parses all required fields correctly', () {
      final result = SettlementItem.fromJson(fullJson());
      expect(result.id, 'item-1');
      expect(result.partnerId, 'partner-1');
      expect(result.currency, 'KRW');
      expect(result.sourceType, 'EVENT');
      expect(result.sourceId, 'evt-1');
      expect(result.status, 'COMPLETED');
      expect(result.grossAmount, 100000);
      expect(result.platformFeeRate, 0.05);
      expect(result.platformFeeAmount, 5000);
      expect(result.pgFeeRate, 0.015);
      expect(result.pgFeeAmount, 1500);
      expect(result.vatRate, 0.1);
      expect(result.vatAmount, 500);
      expect(result.netAmount, 93000);
      expect(result.retryable, isFalse);
      expect(result.retryCount, 0);
      expect(result.calcChecksum, 'abc123');
      expect(result.version, 1);
    });

    test('parses DateTime fields', () {
      final result = SettlementItem.fromJson(fullJson());
      expect(result.createdAt.year, 2026);
      expect(result.updatedAt.year, 2026);
      expect(result.settlementPeriodStart.year, 2026);
      expect(result.settlementPeriodEnd.month, 1);
    });

    test('optional fields are null when absent', () {
      final result = SettlementItem.fromJson(fullJson());
      expect(result.holdReasonCode, isNull);
      expect(result.holdReasonDetail, isNull);
      expect(result.failureReasonCode, isNull);
      expect(result.failureMessage, isNull);
      expect(result.nextRetryAt, isNull);
      expect(result.payoutId, isNull);
      expect(result.eventCompletedAt, isNull);
    });

    test('parses optional nullable fields when present', () {
      final json = {
        ...fullJson(),
        'hold_reason_code': 'VERIFICATION_REQUIRED',
        'hold_reason_detail': '파트너 계좌 미등록',
        'failure_reason_code': 'BANK_ERROR',
        'failure_message': '은행 오류',
        'payout_id': 'payout-1',
        'next_retry_at': '2026-01-20T00:00:00.000Z',
        'event_completed_at': '2026-01-15T22:00:00.000Z',
      };
      final result = SettlementItem.fromJson(json);
      expect(result.holdReasonCode, 'VERIFICATION_REQUIRED');
      expect(result.holdReasonDetail, '파트너 계좌 미등록');
      expect(result.failureReasonCode, 'BANK_ERROR');
      expect(result.failureMessage, '은행 오류');
      expect(result.payoutId, 'payout-1');
      expect(result.nextRetryAt, isA<DateTime>());
      expect(result.eventCompletedAt, isA<DateTime>());
    });

    test('defaults string fields when null', () {
      final result = SettlementItem.fromJson({
        'id': null,
        'partner_id': null,
        'settlement_period_start': '2026-01-01',
        'settlement_period_end': '2026-01-31',
        'currency': null,
        'source_type': null,
        'source_id': null,
        'status': null,
        'gross_amount': 0,
        'platform_fee_rate': 0.0,
        'platform_fee_amount': 0,
        'pg_fee_rate': 0.0,
        'pg_fee_amount': 0,
        'vat_rate': 0.0,
        'vat_amount': 0,
        'net_amount': 0,
        'retryable': null,
        'retry_count': 0,
        'calc_checksum': null,
        'version': 0,
        'created_at': '2026-01-15T10:00:00.000Z',
        'updated_at': '2026-01-15T10:00:00.000Z',
      });
      expect(result.id, '');
      expect(result.partnerId, '');
      expect(result.currency, 'KRW');
      expect(result.sourceType, '');
      expect(result.sourceId, '');
      expect(result.status, 'PENDING');
      expect(result.retryable, isFalse);
      expect(result.calcChecksum, '');
    });

    test('_toDouble handles string, num and double', () {
      // Via pgFeeRate / vatRate
      final result = SettlementItem.fromJson({
        ...fullJson(),
        'platform_fee_rate': '0.05',
        'pg_fee_rate': 0.015,
        'vat_rate': 1, // int that should become 1.0
      });
      expect(result.platformFeeRate, 0.05);
      expect(result.pgFeeRate, 0.015);
      expect(result.vatRate, 1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // SettlementItemStatus constants
  // ---------------------------------------------------------------------------
  group('SettlementItemStatus', () {
    test('has the expected status constants', () {
      expect(SettlementItemStatus.pending, 'PENDING');
      expect(SettlementItemStatus.hold, 'HOLD');
      expect(SettlementItemStatus.canceled, 'CANCELED');
      expect(SettlementItemStatus.ready, 'READY');
      expect(SettlementItemStatus.processing, 'PROCESSING');
      expect(SettlementItemStatus.completed, 'COMPLETED');
      expect(SettlementItemStatus.failed, 'FAILED');
    });
  });
}
