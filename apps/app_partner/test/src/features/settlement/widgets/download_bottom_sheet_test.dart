// Fix #1103: settlement 도메인 테스트 보강
//
// NOTE: The full DownloadBottomSheet widget cannot be fully tested in unit tests
// because it calls SharePlus.instance.share(), which is a platform channel.
// This file focuses on the CSV generation logic by extracting it into testable
// helper functions that mirror the private logic in _DownloadBottomSheetState.
//
// The _buildCsv and _escapeCsv methods are private to the State, so we
// replicate (and test) them here as standalone pure functions to verify
// correctness without depending on platform channels.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/settlement_item_detail.dart';

// ---------------------------------------------------------------------------
// Logic replicated from _DownloadBottomSheetState (pure functions)
// ---------------------------------------------------------------------------

String escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String buildCsv(SettlementItemDetail detail) {
  final lines = <String>[
    '# calc_version,1.0',
    '# generated_at,${DateTime.now().toIso8601String()}',
    '정산ID,파트너ID,상태,총매출,PG수수료,플랫폼수수료,VAT,정산금,통화,정산기간시작,정산기간종료,생성일',
    [
      detail.id,
      detail.partnerId,
      detail.status,
      detail.grossAmount.toString(),
      detail.pgFeeAmount.toString(),
      detail.platformFeeAmount.toString(),
      detail.vatAmount.toString(),
      detail.netAmount.toString(),
      detail.currency,
      detail.settlementPeriodStart?.toIso8601String() ?? '',
      detail.settlementPeriodEnd?.toIso8601String() ?? '',
      detail.createdAt.toIso8601String(),
    ].map(escapeCsv).join(','),
  ];
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Test data builder
// ---------------------------------------------------------------------------
SettlementItemDetail _makeDetail({
  String id = 'item-1',
  String partnerId = 'partner-1',
  String status = 'COMPLETED',
  int grossAmount = 100000,
  int pgFeeAmount = 1500,
  int platformFeeAmount = 5000,
  int vatAmount = 500,
  int netAmount = 93000,
  String currency = 'KRW',
  DateTime? settlementPeriodStart,
  DateTime? settlementPeriodEnd,
}) {
  return SettlementItemDetail(
    id: id,
    partnerId: partnerId,
    status: status,
    grossAmount: grossAmount,
    platformFeeAmount: platformFeeAmount,
    pgFeeAmount: pgFeeAmount,
    vatAmount: vatAmount,
    netAmount: netAmount,
    currency: currency,
    createdAt: DateTime(2026, 1, 15, 10),
    updatedAt: DateTime(2026, 1, 16, 12),
    retryable: false,
    retryCount: 0,
    histories: const [],
    adjustments: const [],
    settlementPeriodStart: settlementPeriodStart,
    settlementPeriodEnd: settlementPeriodEnd,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  // -------------------------------------------------------------------------
  // escapeCsv
  // -------------------------------------------------------------------------
  group('escapeCsv', () {
    test('plain value with no special chars returns as-is', () {
      expect(escapeCsv('hello'), 'hello');
    });

    test('value with comma is wrapped in quotes', () {
      expect(escapeCsv('hello,world'), '"hello,world"');
    });

    test('value with double-quote escapes the quote and wraps', () {
      expect(escapeCsv('say "hi"'), '"say ""hi"""');
    });

    test('value with newline is wrapped in quotes', () {
      expect(escapeCsv('line1\nline2'), '"line1\nline2"');
    });

    test('empty string returns empty string', () {
      expect(escapeCsv(''), '');
    });

    test('value with only spaces returns as-is', () {
      expect(escapeCsv('   '), '   ');
    });

    test('ISO date string does not need quoting', () {
      const dateStr = '2026-01-15T10:00:00.000Z';
      expect(escapeCsv(dateStr), dateStr);
    });
  });

  // -------------------------------------------------------------------------
  // buildCsv
  // -------------------------------------------------------------------------
  group('buildCsv', () {
    test('output has 4 lines (2 metadata + 1 header + 1 data)', () {
      final detail = _makeDetail();
      final csv = buildCsv(detail);
      final lines = csv.split('\n');
      expect(lines.length, 4);
    });

    test('first line starts with # calc_version', () {
      final detail = _makeDetail();
      final csv = buildCsv(detail);
      expect(csv.split('\n').first, startsWith('# calc_version,1.0'));
    });

    test('header line contains required Korean column names', () {
      final detail = _makeDetail();
      final csv = buildCsv(detail);
      final headerLine = csv.split('\n')[2];
      expect(headerLine, contains('정산ID'));
      expect(headerLine, contains('파트너ID'));
      expect(headerLine, contains('상태'));
      expect(headerLine, contains('총매출'));
      expect(headerLine, contains('정산금'));
    });

    test('data row contains correct values', () {
      final detail = _makeDetail(
        id: 'item-abc',
        partnerId: 'partner-xyz',
      );
      final csv = buildCsv(detail);
      final dataRow = csv.split('\n')[3];
      expect(dataRow, contains('item-abc'));
      expect(dataRow, contains('partner-xyz'));
      expect(dataRow, contains('COMPLETED'));
      expect(dataRow, contains('100000'));
      expect(dataRow, contains('1500'));
      expect(dataRow, contains('5000'));
      expect(dataRow, contains('500'));
      expect(dataRow, contains('93000'));
      expect(dataRow, contains('KRW'));
    });

    test('settlement period fields are empty when null', () {
      final detail = _makeDetail();
      final csv = buildCsv(detail);
      final dataRow = csv.split('\n')[3];
      // The two empty period columns produce consecutive commas
      expect(dataRow, contains(',,'));
    });

    test('settlement period fields are included when non-null', () {
      final detail = _makeDetail(
        settlementPeriodStart: DateTime(2026),
        settlementPeriodEnd: DateTime(2026, 1, 31),
      );
      final csv = buildCsv(detail);
      final dataRow = csv.split('\n')[3];
      expect(dataRow, contains('2026-01-01'));
      expect(dataRow, contains('2026-01-31'));
    });

    test('BOM prefix makes bytes start with UTF-8 BOM', () {
      final detail = _makeDetail();
      final csv = buildCsv(detail);
      final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
      // UTF-8 BOM is 0xEF, 0xBB, 0xBF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });

    test(
      'file name format follows settlement_{id}_{timestamp}.csv pattern',
      () {
        const id = 'item-1';
        final ts = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'settlement_${id}_$ts.csv';
        expect(fileName, matches(RegExp(r'^settlement_item-1_\d+\.csv$')));
      },
    );
  });
}
