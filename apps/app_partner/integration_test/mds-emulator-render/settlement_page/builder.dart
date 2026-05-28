// SettlementPageBuilder — settlement_page 전용 fluent API.
//
// SettlementPage 는 현재 파트너 정보 + 정산 repository를 기준으로
// 대시보드/목록 탭 상태를 렌더한다. MDS render에서는 provider override로
// loading/empty/error를 결정적으로 재현한다.

import 'package:app_partner/src/features/settlement/settlement_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

enum _SettlementScenario { loading, empty, error }

class _FakeSettlementRepository implements SettlementRepository {
  _FakeSettlementRepository({required this.scenario});

  final _SettlementScenario scenario;

  @override
  Future<Map<String, dynamic>> getSettlementDashboard({
    required String partnerId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    if (scenario == _SettlementScenario.error) {
      throw Exception('render: forced settlement dashboard error');
    }
    return {
      'completed_gross_total': 0,
      'completed_net_total': 0,
      'pending_gross_total': 0,
      'status_counts': <String, int>{},
    };
  }

  @override
  Future<List<SettlementItemDetail>> getSettlementItems({
    required String partnerId,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    int limit = 20,
    int offset = 0,
  }) async {
    if (scenario == _SettlementScenario.error) {
      throw Exception('render: forced settlement list error');
    }
    return const <SettlementItemDetail>[];
  }

  @override
  Future<Map<String, dynamic>?> getBankAccount(String partnerId) =>
      throw UnimplementedError();

  @override
  Future<void> upsertBankAccount({
    required String partnerId,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
  }) => throw UnimplementedError();

  @override
  Future<SettlementItemDetail?> getSettlementItemDetail(String itemId) =>
      throw UnimplementedError();

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

class SettlementPageBuilder extends MdsScreenBuilder<SettlementPage> {
  SettlementPageBuilder() : super(page: const SettlementPage());

  _SettlementScenario _scenario = _SettlementScenario.empty;
  Brightness _brightness = Brightness.light;

  SettlementPageBuilder loading() {
    _scenario = _SettlementScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementPageBuilder empty() {
    _scenario = _SettlementScenario.empty;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementPageBuilder error() {
    _scenario = _SettlementScenario.error;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  SettlementPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;
    final isLoading = scenario == _SettlementScenario.loading;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        currentMemberPermissionsProvider.overrideWith(
          (ref) async => const <String>[],
        ),
        currentPartnerInfoProvider.overrideWith((ref) async {
          if (isLoading) {
            await Future<void>.delayed(const Duration(days: 1));
          }
          return mockPartner();
        }),
        settlementRepositoryProvider.overrideWith(
          (_) => _FakeSettlementRepository(scenario: scenario),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const SettlementPage(),
      ),
    );
  }
}
