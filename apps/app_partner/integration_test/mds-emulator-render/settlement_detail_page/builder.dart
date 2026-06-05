// SettlementDetailPageBuilder - settlement_detail_page 전용 fluent API.
//
// SettlementDetailPage 는 settlementRepositoryProvider 를 통해 상세 데이터를
// 로드한다. MDS render에서는 fake repository로 상태를 고정해
// COMPLETED / PENDING / FAILED / HOLD / LOADING 상태를 결정적으로 재현한다.

import 'dart:async';

import 'package:app_partner/src/features/settlement/settlement_detail_page.dart';
import 'package:app_partner/src/features/settlement/widgets/download_bottom_sheet.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

enum _SettlementDetailScenario {
  completed,
  pending,
  failed,
  hold,
  loading,
}

class _FakeSettlementRepository implements SettlementRepository {
  _FakeSettlementRepository({required this.scenario});

  final _SettlementDetailScenario scenario;

  static final DateTime _base = DateTime.utc(2026, 5, 29, 2);

  SettlementItemDetail _detail({
    required String status,
    required bool retryable,
    List<SettlementHistoryEntry> histories = const <SettlementHistoryEntry>[],
  }) {
    return SettlementItemDetail(
      id: 'mock-settlement-item-1',
      partnerId: 'mock-partner-1',
      status: status,
      grossAmount: 560000,
      platformFeeAmount: 56000,
      pgFeeAmount: 16800,
      vatAmount: 5600,
      netAmount: 481600,
      currency: 'KRW',
      createdAt: _base,
      updatedAt: _base,
      retryable: retryable,
      retryCount: retryable ? 1 : 0,
      histories: histories,
      adjustments: const <AdjustmentItemModel>[],
      payoutId: retryable ? 'mock-payout-1' : null,
    );
  }

  @override
  Future<SettlementItemDetail?> getSettlementItemDetail(String itemId) async {
    switch (scenario) {
      case _SettlementDetailScenario.completed:
        return _detail(
          status: 'COMPLETED',
          retryable: false,
          histories: <SettlementHistoryEntry>[
            SettlementHistoryEntry(
              eventType: 'STATUS_CHANGED',
              fromStatus: 'PENDING',
              toStatus: 'READY',
              createdAt: _base.subtract(const Duration(days: 3)),
            ),
            SettlementHistoryEntry(
              eventType: 'STATUS_CHANGED',
              fromStatus: 'READY',
              toStatus: 'PROCESSING',
              createdAt: _base.subtract(const Duration(days: 2)),
            ),
            SettlementHistoryEntry(
              eventType: 'STATUS_CHANGED',
              fromStatus: 'PROCESSING',
              toStatus: 'COMPLETED',
              createdAt: _base.subtract(const Duration(days: 1)),
            ),
          ],
        );
      case _SettlementDetailScenario.pending:
        return _detail(
          status: 'PENDING',
          retryable: false,
        );
      case _SettlementDetailScenario.failed:
        return _detail(
          status: 'FAILED',
          retryable: true,
          histories: <SettlementHistoryEntry>[
            SettlementHistoryEntry(
              eventType: 'STATUS_CHANGED',
              fromStatus: 'PROCESSING',
              toStatus: 'FAILED',
              createdAt: _base.subtract(const Duration(hours: 5)),
            ),
          ],
        );
      case _SettlementDetailScenario.hold:
        return _detail(
          status: 'HOLD',
          retryable: false,
        );
      case _SettlementDetailScenario.loading:
        return Future<SettlementItemDetail?>.delayed(const Duration(days: 1));
    }
  }

  @override
  Future<Map<String, dynamic>> getSettlementDashboard({
    required String partnerId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) => throw UnimplementedError();

  @override
  Future<List<SettlementItemDetail>> getSettlementItems({
    required String partnerId,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    int limit = 20,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getBankAccount(String partnerId) =>
      throw UnimplementedError();

  @override
  Future<void> upsertBankAccount({
    required String partnerId,
    required String bankCode,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
  }) => throw UnimplementedError();

  @override
  Future<void> requestManualBankAccountReview({
    required String partnerId,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getEventInfo(String eventId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getPartnerSettlementInfo(String partnerId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> retryPayout({
    required String payoutId,
    required String partnerId,
  }) => throw UnimplementedError();
}

class SettlementDetailPageBuilder
    extends MdsScreenBuilder<SettlementDetailPage> {
  SettlementDetailPageBuilder()
    : super(page: const SettlementDetailPage(itemId: 'mock-settlement-item-1'));

  _SettlementDetailScenario _scenario = _SettlementDetailScenario.completed;
  Brightness _brightness = Brightness.light;
  bool _showDownloadSheet = false;

  SettlementDetailPageBuilder completed() {
    _scenario = _SettlementDetailScenario.completed;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder pending() {
    _scenario = _SettlementDetailScenario.pending;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder failed() {
    _scenario = _SettlementDetailScenario.failed;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder hold() {
    _scenario = _SettlementDetailScenario.hold;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder loading() {
    _scenario = _SettlementDetailScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder downloadSheet() {
    _scenario = _SettlementDetailScenario.completed;
    _showDownloadSheet = true;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementDetailPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        currentPartnerInfoProvider.overrideWith((_) async => mockPartner()),
        settlementRepositoryProvider.overrideWith(
          (_) => _FakeSettlementRepository(scenario: _scenario),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: _showDownloadSheet
            ? _DownloadSheetHarness(
                detail: _FakeSettlementRepository(
                  scenario: _SettlementDetailScenario.completed,
                )._detail(status: 'COMPLETED', retryable: false),
                child: const SettlementDetailPage(
                  itemId: 'mock-settlement-item-1',
                ),
              )
            : const SettlementDetailPage(itemId: 'mock-settlement-item-1'),
      ),
    );
  }
}

class _DownloadSheetHarness extends StatefulWidget {
  const _DownloadSheetHarness({
    required this.detail,
    required this.child,
  });

  final SettlementItemDetail detail;
  final Widget child;

  @override
  State<_DownloadSheetHarness> createState() => _DownloadSheetHarnessState();
}

class _DownloadSheetHarnessState extends State<_DownloadSheetHarness> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(DownloadBottomSheet.show(context, widget.detail));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
