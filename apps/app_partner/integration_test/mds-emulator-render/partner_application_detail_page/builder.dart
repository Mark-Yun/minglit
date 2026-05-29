import 'dart:async';

import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const _mockApplicationId = 'render-application-id';

enum _PartnerApplicationDetailScenario {
  pending,
  approved,
  rejected,
  needsCorrection,
  loading,
  notFound,
}

class PartnerApplicationDetailPageBuilder
    extends MdsScreenBuilder<PartnerApplicationDetailPage> {
  PartnerApplicationDetailPageBuilder()
    : super(
        page: const PartnerApplicationDetailPage(
          applicationId: _mockApplicationId,
        ),
      );

  _PartnerApplicationDetailScenario _scenario =
      _PartnerApplicationDetailScenario.pending;

  PartnerApplicationDetailPageBuilder pending() {
    _scenario = _PartnerApplicationDetailScenario.pending;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplicationDetailPageBuilder approved() {
    _scenario = _PartnerApplicationDetailScenario.approved;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplicationDetailPageBuilder rejected() {
    _scenario = _PartnerApplicationDetailScenario.rejected;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplicationDetailPageBuilder needsCorrection() {
    _scenario = _PartnerApplicationDetailScenario.needsCorrection;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplicationDetailPageBuilder loading() {
    _scenario = _PartnerApplicationDetailScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplicationDetailPageBuilder notFound() {
    _scenario = _PartnerApplicationDetailScenario.notFound;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        partnerApplicationProvider(
          applicationId: _mockApplicationId,
        ).overrideWith((
          ref,
        ) async {
          switch (scenario) {
            case _PartnerApplicationDetailScenario.pending:
              return _buildApplication(status: 'pending');
            case _PartnerApplicationDetailScenario.approved:
              return _buildApplication(
                status: 'approved',
                adminComment: '서류 확인 완료. 승인합니다.',
              );
            case _PartnerApplicationDetailScenario.rejected:
              return _buildApplication(
                status: 'rejected',
                adminComment: '사업자 정보가 확인되지 않습니다.',
              );
            case _PartnerApplicationDetailScenario.needsCorrection:
              return _buildApplication(
                status: 'needs_correction',
                adminComment: '통장 사본 해상도가 낮아 재업로드가 필요합니다.',
              );
            case _PartnerApplicationDetailScenario.loading:
              return Completer<PartnerApplication?>().future;
            case _PartnerApplicationDetailScenario.notFound:
              return null;
          }
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: MinglitTheme.materialTheme,
        home: const PartnerApplicationDetailPage(
          applicationId: _mockApplicationId,
        ),
      ),
    );
  }

  PartnerApplication _buildApplication({
    required String status,
    String? adminComment,
  }) {
    return PartnerApplication(
      id: _mockApplicationId,
      userId: 'render-user-id',
      status: status,
      brandName: '밍글릿 로스터리',
      bizName: '밍글릿 로스터리 주식회사',
      representativeName: '김대표',
      bizNumber: '123-45-67890',
      contactPhone: '010-1234-5678',
      address: '서울시 성동구 성수이로 77',
      bizRegistrationPath: 'render/biz_registration.pdf',
      bankbookPath: 'render/bankbook.png',
      adminComment: adminComment,
    );
  }
}
