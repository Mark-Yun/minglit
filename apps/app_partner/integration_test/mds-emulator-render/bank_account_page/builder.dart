// BankAccountPageBuilder — bank_account_page 전용 fluent API.
//
// BankAccountPage 는 ConsumerStatefulWidget 으로, initState() 에서
// currentPartnerInfoProvider.future 와 settlementRepositoryProvider 를 직접 read.
// - loading: currentPartnerInfoProvider 를 무한 지연으로 override
// - no-account: partner 있음 + getBankAccount null 반환
// - with-account: partner 있음 + getBankAccount mock 데이터 반환

import 'package:app_partner/src/features/settlement/bank_account_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

/// _FakeSettlementRepository — Supabase 없이 결정적 데이터 반환.
class _FakeSettlementRepository implements SettlementRepository {
  _FakeSettlementRepository({this.bankAccountData});

  final Map<String, dynamic>? bankAccountData;

  @override
  Future<Map<String, dynamic>?> getBankAccount(String partnerId) async =>
      bankAccountData;

  @override
  Future<void> upsertBankAccount({
    required String partnerId,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
  }) async {}

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
  Future<SettlementItemDetail?> getSettlementItemDetail(String itemId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getSettlementDashboard({
    required String partnerId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getEventInfo(String eventId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> getPartnerSettlementInfo(
    String partnerId,
  ) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> retryPayout({
    required String payoutId,
    required String partnerId,
  }) => throw UnimplementedError();
}

class BankAccountPageBuilder extends MdsScreenBuilder<BankAccountPage> {
  BankAccountPageBuilder() : super(page: const BankAccountPage());

  bool _isLoading = false;
  Map<String, dynamic>? _bankAccountData;
  Partner? _partner;
  Brightness _brightness = Brightness.light;

  /// loading 상태 — partner 정보 로딩 중, spinner 표시.
  BankAccountPageBuilder loading() {
    _isLoading = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// partner 있음, 등록된 계좌 없음.
  BankAccountPageBuilder withNoAccount() {
    _partner = mockPartner();
    _bankAccountData = null;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// partner 있음, 계좌 정보 있음.
  BankAccountPageBuilder withAccount() {
    _partner = mockPartner();
    _bankAccountData = mockBankAccount();
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  BankAccountPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final isLoading = _isLoading;
    final partner = _partner;
    final bankAccountData = _bankAccountData;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        currentPartnerInfoProvider.overrideWith((ref) async {
          if (isLoading) {
            await Future<void>.delayed(const Duration(days: 1));
          }
          return partner;
        }),
        if (partner != null)
          settlementRepositoryProvider.overrideWith(
            (_) => _FakeSettlementRepository(bankAccountData: bankAccountData),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const BankAccountPage(),
      ),
    );
  }
}
