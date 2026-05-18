/// Settlement-domain fixtures: `SettlementItemDetail` records and bank
/// account info for `demoPartnerSelf`.
///
/// Owned by **P1-4 agent**. See task #14.
///
/// State distribution (6 items):
///   - 1 × PENDING   (last month — current cycle)
///   - 4 × COMPLETED (months -2 through -5)
///   - 1 × FAILED    (month -6, with retryable=true)
library;

import 'package:minglit_kit/minglit_kit.dart';

import 'demo_world.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

SettlementItemDetail _makeItem({
  required String id,
  required String status,
  required int grossAmount,
  required DateTime periodStart,
  required DateTime periodEnd,
  String? eventId,
  String? payoutId,
  String? failureReasonCode,
  String? failureMessage,
  bool retryable = false,
  List<SettlementHistoryEntry> histories = const [],
}) {
  // Platform fee 10%, PG fee 3.3%, VAT 10% of platform fee
  final platformFee = (grossAmount * 0.10).round();
  final pgFee = (grossAmount * 0.033).round();
  final vat = (platformFee * 0.10).round();
  final net = grossAmount - platformFee - pgFee - vat;

  return SettlementItemDetail(
    id: id,
    partnerId: DemoWorld.selfPartnerId,
    eventId: eventId,
    status: status,
    grossAmount: grossAmount,
    platformFeeAmount: platformFee,
    pgFeeAmount: pgFee,
    vatAmount: vat,
    netAmount: net,
    currency: 'KRW',
    settlementPeriodStart: periodStart,
    settlementPeriodEnd: periodEnd,
    processingStartedAt:
        status == 'COMPLETED' ? periodEnd.add(const Duration(days: 1)) : null,
    processingEndedAt:
        status == 'COMPLETED' ? periodEnd.add(const Duration(days: 3)) : null,
    createdAt: periodStart,
    updatedAt: status == 'COMPLETED'
        ? periodEnd.add(const Duration(days: 3))
        : periodStart,
    payoutId: payoutId,
    retryable: retryable,
    retryCount: retryable ? 1 : 0,
    failureReasonCode: failureReasonCode,
    failureMessage: failureMessage,
    histories: histories,
    adjustments: const [],
  );
}

DateTime _monthStart(int monthsAgo) {
  final ref = DemoWorld.now;
  var year = ref.year;
  var month = ref.month - monthsAgo;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  return DateTime.utc(year, month, 1);
}

DateTime _monthEnd(int monthsAgo) {
  // Last second of the month: start of next month minus 1 second.
  final nextMonth = _monthStart(monthsAgo - 1);
  return nextMonth.subtract(const Duration(seconds: 1));
}

// ── Settlement Items ──────────────────────────────────────────────────────────

/// Last 6 months of settlement items for demoPartnerSelf.
final List<SettlementItemDetail> demoSettlementItems = [
  // Month -1: PENDING (current cycle, not yet processed)
  _makeItem(
    id: '00000000-0000-4000-8000-600000000001',
    status: 'PENDING',
    grossAmount: 1_850_000,
    periodStart: _monthStart(1),
    periodEnd: _monthEnd(1),
    eventId: DemoWorld.selfEvent3Id,
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'CREATED',
        toStatus: 'PENDING',
        createdAt: _monthStart(1).add(const Duration(days: 2)),
      ),
    ],
  ),

  // Month -2: COMPLETED
  _makeItem(
    id: '00000000-0000-4000-8000-600000000002',
    status: 'COMPLETED',
    grossAmount: 2_400_000,
    periodStart: _monthStart(2),
    periodEnd: _monthEnd(2),
    eventId: DemoWorld.selfEvent2Id,
    payoutId: '00000000-0000-4000-8000-700000000002',
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PENDING',
        toStatus: 'PROCESSING',
        createdAt: _monthEnd(2).add(const Duration(days: 1)),
      ),
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PROCESSING',
        toStatus: 'COMPLETED',
        createdAt: _monthEnd(2).add(const Duration(days: 3)),
      ),
    ],
  ),

  // Month -3: COMPLETED
  _makeItem(
    id: '00000000-0000-4000-8000-600000000003',
    status: 'COMPLETED',
    grossAmount: 3_100_000,
    periodStart: _monthStart(3),
    periodEnd: _monthEnd(3),
    eventId: DemoWorld.selfEvent1Id,
    payoutId: '00000000-0000-4000-8000-700000000003',
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PENDING',
        toStatus: 'PROCESSING',
        createdAt: _monthEnd(3).add(const Duration(days: 1)),
      ),
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PROCESSING',
        toStatus: 'COMPLETED',
        createdAt: _monthEnd(3).add(const Duration(days: 3)),
      ),
    ],
  ),

  // Month -4: COMPLETED
  _makeItem(
    id: '00000000-0000-4000-8000-600000000004',
    status: 'COMPLETED',
    grossAmount: 2_750_000,
    periodStart: _monthStart(4),
    periodEnd: _monthEnd(4),
    eventId: DemoWorld.selfEvent2Id,
    payoutId: '00000000-0000-4000-8000-700000000004',
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PENDING',
        toStatus: 'PROCESSING',
        createdAt: _monthEnd(4).add(const Duration(days: 1)),
      ),
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PROCESSING',
        toStatus: 'COMPLETED',
        createdAt: _monthEnd(4).add(const Duration(days: 3)),
      ),
    ],
  ),

  // Month -5: COMPLETED
  _makeItem(
    id: '00000000-0000-4000-8000-600000000005',
    status: 'COMPLETED',
    grossAmount: 1_650_000,
    periodStart: _monthStart(5),
    periodEnd: _monthEnd(5),
    eventId: DemoWorld.selfEvent1Id,
    payoutId: '00000000-0000-4000-8000-700000000005',
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PENDING',
        toStatus: 'PROCESSING',
        createdAt: _monthEnd(5).add(const Duration(days: 1)),
      ),
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PROCESSING',
        toStatus: 'COMPLETED',
        createdAt: _monthEnd(5).add(const Duration(days: 3)),
      ),
    ],
  ),

  // Month -6: FAILED (retryable)
  _makeItem(
    id: '00000000-0000-4000-8000-600000000006',
    status: 'FAILED',
    grossAmount: 980_000,
    periodStart: _monthStart(6),
    periodEnd: _monthEnd(6),
    eventId: DemoWorld.selfEvent1Id,
    retryable: true,
    failureReasonCode: 'BANK_ACCOUNT_INVALID',
    failureMessage: '계좌 정보가 일치하지 않아 송금에 실패하였습니다. 계좌 정보를 확인해주세요.',
    histories: [
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PENDING',
        toStatus: 'PROCESSING',
        createdAt: _monthEnd(6).add(const Duration(days: 1)),
      ),
      SettlementHistoryEntry(
        eventType: 'STATUS_CHANGED',
        fromStatus: 'PROCESSING',
        toStatus: 'FAILED',
        createdAt: _monthEnd(6).add(const Duration(days: 2)),
        details: {'reason': 'BANK_ACCOUNT_INVALID'},
      ),
    ],
  ),
];

// ── Bank Account (partner_settlements row) ────────────────────────────────────

/// Registered + verified bank account fixture for demoPartnerSelf.
/// Returned by `SettlementRepository.getBankAccount` and
/// `getPartnerSettlementInfo` as a raw `Map<String, dynamic>`.
final Map<String, dynamic> demoBankAccount = {
  'partner_id': DemoWorld.selfPartnerId,
  'bank_name': '농협은행',
  'account_number': '301-0000-0001-01',
  'account_holder': '김데모',
  'is_verified': true,
  'created_at':
      DemoWorld.offset(const Duration(days: -180)).toIso8601String(),
  'updated_at':
      DemoWorld.offset(const Duration(days: -180)).toIso8601String(),
};
