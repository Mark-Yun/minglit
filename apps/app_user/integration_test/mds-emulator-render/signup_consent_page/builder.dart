// SignupConsentPageBuilder — signup_consent_page 전용 fluent API.
//
// SignupConsentPage 는 consentControllerProvider 를 listen 해
// 저장된 동의 항목으로 checkbox 를 hydrate 한다 (_didHydrate = true 이후).
//
// 모든 state 는 명시적 override 필요:
//  noneSelected()  — [] 동기 반환 → 체크박스 없음 (State 1)
//  requiredOnly()  — 필수 3개 checked (State 2)
//  allSelected()   — 전체 7개 checked (State 3)
//  loading()       — Completer 미완료 → 스피너 (infiniteAnimation 필수)
//
// State 4 (Submitting) / State 5 (Error) 는 사용자 액션 또는
// 에러 스낵바 의존으로 정적 캡처 제외.

import 'dart:async';

import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

// ── Fake ConsentControllers ──────────────────────────────────────────────────

/// [] 동기 반환 — loading 상태 없이 즉시 hydrate (체크박스 없음).
class _DefaultConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() => [];
}

/// 필수 3개 동기 반환 — hydrate 후 required 체크박스 3개 checked.
class _RequiredOnlyConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() => [
    _consent(ConsentType.termsOfService),
    _consent(ConsentType.privacyCollection),
    _consent(ConsentType.ageConfirmation),
  ];
}

/// 전체 7개 동기 반환 — hydrate 후 모든 체크박스 checked.
class _AllConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() => [
    _consent(ConsentType.termsOfService),
    _consent(ConsentType.privacyCollection),
    _consent(ConsentType.ageConfirmation),
    _consent(ConsentType.thirdPartyProvision),
    _consent(ConsentType.locationConsent),
    _consent(ConsentType.identityVerification),
    _consent(ConsentType.marketingConsent),
  ];
}

/// 미완료 future — isInitialLoading=true 유지 (스피너 표시).
class _LoadingConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() =>
      Completer<List<UserConsent>>().future;
}

UserConsent _consent(ConsentType type) => UserConsent(
  id: 'consent-${type.name}',
  userId: 'mock-user-1',
  consentKey: type,
  consented: true,
  consentedAt: DateTime.utc(2026),
  createdAt: DateTime.utc(2026),
);

// ── Builder ─────────────────────────────────────────────────────────────────

class SignupConsentPageBuilder extends MdsScreenBuilder<SignupConsentPage> {
  SignupConsentPageBuilder() : super(page: const SignupConsentPage());

  /// 로딩 상태 — consentControllerProvider 미완료 (infiniteAnimation 필수).
  SignupConsentPageBuilder loading() {
    addOverride(
      consentControllerProvider.overrideWith(_LoadingConsentController.new),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 체크박스 없음 (none selected) — CTA 비활성 (State 1 baseline).
  SignupConsentPageBuilder noneSelected() {
    addOverride(
      consentControllerProvider.overrideWith(_DefaultConsentController.new),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 필수 3개 checked — CTA 활성 (State 2).
  SignupConsentPageBuilder requiredOnly() {
    addOverride(
      consentControllerProvider.overrideWith(
        _RequiredOnlyConsentController.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 전체 7개 checked (State 3).
  SignupConsentPageBuilder allSelected() {
    addOverride(
      consentControllerProvider.overrideWith(_AllConsentController.new),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 다크 모드 토글.
  SignupConsentPageBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder
    return this;
  }
}
