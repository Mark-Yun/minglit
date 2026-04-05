// Fix #1103: settlement 도메인 테스트 보강

import 'dart:async';

import 'package:app_partner/src/features/settlement/settlement_detail_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SettlementItemDetail _makeDetail({
  String id = 'item-1',
  String status = 'COMPLETED',
  bool retryable = false,
  String? payoutId,
  List<SettlementHistoryEntry>? histories,
}) {
  return SettlementItemDetail(
    id: id,
    partnerId: 'partner-1',
    status: status,
    grossAmount: 100000,
    platformFeeAmount: 5000,
    pgFeeAmount: 1500,
    vatAmount: 500,
    netAmount: 93000,
    currency: 'KRW',
    createdAt: DateTime(2026, 1, 15, 10),
    updatedAt: DateTime(2026, 1, 16, 12),
    retryable: retryable,
    retryCount: 0,
    histories: histories ?? [],
    adjustments: const [],
    payoutId: payoutId,
  );
}

Widget _buildApp({
  required MockSettlementRepository mockSettlementRepo,
  Partner? partner,
}) {
  return ProviderScope(
    overrides: [
      settlementRepositoryProvider.overrideWithValue(mockSettlementRepo),
      currentPartnerInfoProvider.overrideWith(
        (ref) async => partner ?? const Partner(id: 'partner-1', name: 'Test'),
      ),
    ],
    child: const MaterialApp(
      home: SettlementDetailPage(itemId: 'item-1'),
    ),
  );
}

void main() {
  late MockSettlementRepository mockSettlementRepo;

  setUp(() {
    mockSettlementRepo = MockSettlementRepository();
  });

  group('SettlementDetailPage', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      // Use a Completer that never completes to keep the loading state.
      final completer = Completer<SettlementItemDetail?>();
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      // pump(Duration.zero) lets initState run but does not complete the future.
      await tester.pump(Duration.zero);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to avoid pending timer warnings.
      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error UI when repo throws', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('오류가 발생했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('shows not-found message when detail is null', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('정산 항목을 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('renders detail content for COMPLETED status', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail(status: 'COMPLETED'));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('정산 상세'), findsOneWidget);
      // StatusMessageCard message for COMPLETED
      expect(find.text('지급이 완료되었습니다.'), findsOneWidget);
      // AmountBreakdown title
      expect(find.text('금액 내역'), findsOneWidget);
    });

    testWidgets('shows FAILED status message', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail(status: 'FAILED'));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(
        find.text('지급에 실패했습니다. 계좌 정보를 확인해 주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('shows HOLD status message', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail(status: 'HOLD'));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(
        find.text('정산이 보류 중입니다. 지원센터에 문의해 주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('shows history timeline when histories are non-empty',
        (tester) async {
      final histories = [
        SettlementHistoryEntry(
          eventType: 'STATUS_CHANGED',
          fromStatus: 'PENDING',
          toStatus: 'READY',
          createdAt: DateTime(2026, 1, 15, 10),
        ),
      ];
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail(histories: histories));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('처리 이력'), findsOneWidget);
      expect(find.textContaining('PENDING → READY'), findsOneWidget);
    });

    testWidgets('does not show history section when histories are empty',
        (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail(histories: []));

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('처리 이력'), findsNothing);
    });

    testWidgets(
      'shows retry button for FAILED + retryable status with payoutId',
      (tester) async {
        when(
          () => mockSettlementRepo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async => _makeDetail(
            status: 'FAILED',
            retryable: true,
            payoutId: 'payout-1',
          ),
        );

        await tester.pumpWidget(
          _buildApp(mockSettlementRepo: mockSettlementRepo),
        );
        await tester.pumpAndSettle();

        expect(find.text('재지급 요청'), findsOneWidget);
      },
    );

    testWidgets(
      'does not show retry button for FAILED + retryable=false',
      (tester) async {
        when(
          () => mockSettlementRepo.getSettlementItemDetail(any()),
        ).thenAnswer(
          (_) async =>
              _makeDetail(status: 'FAILED', retryable: false, payoutId: 'p-1'),
        );

        await tester.pumpWidget(
          _buildApp(mockSettlementRepo: mockSettlementRepo),
        );
        await tester.pumpAndSettle();

        expect(find.text('재지급 요청'), findsNothing);
      },
    );

    testWidgets('always shows CSV download button', (tester) async {
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async => _makeDetail());

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('CSV 다운로드'), findsOneWidget);
    });

    testWidgets('retry button triggers re-load on error tap', (tester) async {
      var callCount = 0;
      when(
        () => mockSettlementRepo.getSettlementItemDetail(any()),
      ).thenAnswer((_) async {
        callCount++;
        throw Exception('fail');
      });

      await tester.pumpWidget(_buildApp(mockSettlementRepo: mockSettlementRepo));
      await tester.pumpAndSettle();

      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      // Second call was triggered
      expect(callCount, greaterThan(1));
    });
  });

  group('StatusMessageCard', () {
    testWidgets('PENDING shows correct message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusMessageCard(status: 'PENDING')),
        ),
      );
      expect(find.text('정산이 확정되기를 기다리고 있습니다.'), findsOneWidget);
    });

    testWidgets('unknown status shows fallback message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusMessageCard(status: 'SOME_UNKNOWN')),
        ),
      );
      expect(find.text('상태를 확인 중입니다.'), findsOneWidget);
    });
  });

  group('AmountBreakdown', () {
    testWidgets('displays all fee rows', (tester) async {
      final detail = _makeDetail();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AmountBreakdown(detail: detail)),
        ),
      );
      expect(find.text('총 매출'), findsOneWidget);
      expect(find.text('PG 수수료'), findsOneWidget);
      expect(find.text('플랫폼 수수료'), findsOneWidget);
      expect(find.text('VAT'), findsOneWidget);
      expect(find.text('정산금'), findsOneWidget);
    });
  });
}
