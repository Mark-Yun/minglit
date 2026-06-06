// PartnerApplyStatusPageBuilder — partner_apply_status_page 전용 fluent API.
//
// onboardingStateProvider + partnerRepositoryProvider 의존을 render 전용
// override로 고정해 pending / needs-correction 상태를 deterministic하게
// 재현한다.

import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

enum _Scenario {
  pending,
  needsCorrection,
  needsCorrectionWithComment,
  loading,
  error,
}

class _FakePartnerRepository implements PartnerRepository {
  _FakePartnerRepository(this._application);

  final PartnerApplication? _application;

  @override
  Future<PartnerApplication?> getMyApplication() async => _application;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PartnerApplyStatusPageBuilder
    extends MdsScreenBuilder<PartnerApplyStatusPage> {
  PartnerApplyStatusPageBuilder() : super(page: const PartnerApplyStatusPage());

  _Scenario _scenario = _Scenario.pending;

  PartnerApplyStatusPageBuilder pending() {
    _scenario = _Scenario.pending;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplyStatusPageBuilder needsCorrection() {
    _scenario = _Scenario.needsCorrection;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplyStatusPageBuilder needsCorrectionWithComment() {
    _scenario = _Scenario.needsCorrectionWithComment;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplyStatusPageBuilder loading() {
    _scenario = _Scenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerApplyStatusPageBuilder error() {
    _scenario = _Scenario.error;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;

    final application = switch (scenario) {
      _Scenario.pending => const PartnerApplication(
        id: 'render-application-1',
        userId: 'render-user-1',
        status: 'pending',
      ),
      _Scenario.needsCorrection => const PartnerApplication(
        id: 'render-application-2',
        userId: 'render-user-1',
        status: 'needs_correction',
      ),
      _Scenario.needsCorrectionWithComment => const PartnerApplication(
        id: 'render-application-3',
        userId: 'render-user-1',
        status: 'needs_correction',
        adminComment: '사업자등록증 이미지가 흐립니다. 재업로드해주세요.',
      ),
      _Scenario.loading || _Scenario.error => null,
    };

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        onboardingStateProvider.overrideWith((_) async {
          switch (scenario) {
            case _Scenario.pending:
              return OnboardingState.pendingReview;
            case _Scenario.needsCorrection:
            case _Scenario.needsCorrectionWithComment:
              return OnboardingState.needsCorrection;
            case _Scenario.loading:
              await Future<void>.delayed(const Duration(days: 1));
              return OnboardingState.pendingReview;
            case _Scenario.error:
              throw StateError('MDS render forced onboarding status error');
          }
        }),
        partnerRepositoryProvider.overrideWith(
          (_) => _FakePartnerRepository(application),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: MinglitTheme.materialTheme,
        home: const PartnerApplyStatusPage(),
      ),
    );
  }
}
