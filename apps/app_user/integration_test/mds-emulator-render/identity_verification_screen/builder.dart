// IdentityVerificationScreenBuilder
// — identity_verification_screen 전용 fluent API.
//
// Iamport 외부 연동 호출 없이 화면 상태를 재현하기 위해
// currentUserProvider / consentRepositoryProvider 를 mock override 한다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_engine/builder.dart';

class _MockUser extends Mock implements User {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _PendingConsentRepository extends ConsentRepository {
  _PendingConsentRepository() : super(_MockSupabaseClient());

  @override
  Future<List<UserConsent>> getConsents(String userId) =>
      Completer<List<UserConsent>>().future;
}

class _NoIdentityConsentRepository extends ConsentRepository {
  _NoIdentityConsentRepository() : super(_MockSupabaseClient());

  @override
  Future<List<UserConsent>> getConsents(String userId) async => const [];
}

class _IdentityConsentRepository extends ConsentRepository {
  _IdentityConsentRepository() : super(_MockSupabaseClient());

  @override
  Future<List<UserConsent>> getConsents(String userId) async {
    final now = DateTime(2026);
    return [
      UserConsent(
        id: 'consent-identity-verification',
        userId: userId,
        consentKey: ConsentType.identityVerification,
        consented: true,
        consentedAt: now,
        createdAt: now,
      ),
    ];
  }
}

Future<String?> _cancelCertification({
  required BuildContext context,
  required String userCode,
  required String merchantUid,
  String? mRedirectUrl,
}) async => null;

User _makeUser() {
  final user = _MockUser();
  when(() => user.id).thenReturn('mock-user-1');
  return user;
}

class IdentityVerificationScreenBuilder
    extends MdsScreenBuilder<IdentityVerificationScreen> {
  IdentityVerificationScreenBuilder()
    : super(
        page: const IdentityVerificationScreen(
          certificationStarter: _cancelCertification,
        ),
      );

  User? _user;
  ConsentRepository? _consentRepository;
  Brightness _brightness = Brightness.light;

  /// 동의 조회를 지연시켜 로딩 상태를 고정한다.
  IdentityVerificationScreenBuilder loading() {
    _user = _makeUser();
    _consentRepository = _PendingConsentRepository();
    // ignore: avoid_returning_this, fluent builder — callers chain b.loading().dark()
    return this;
  }

  /// 동의 시트를 노출한다 (identity_verification 동의 없음).
  IdentityVerificationScreenBuilder withConsentSheet() {
    _user = _makeUser();
    _consentRepository = _NoIdentityConsentRepository();
    // ignore: avoid_returning_this, fluent builder — callers chain b.withConsentSheet().dark()
    return this;
  }

  /// 인증 창 취소/실패 후 오류 + 재시도 버튼 상태를 노출한다.
  IdentityVerificationScreenBuilder errorRetry() {
    _user = _makeUser();
    _consentRepository = _IdentityConsentRepository();
    // ignore: avoid_returning_this, fluent builder — callers chain b.errorRetry().dark()
    return this;
  }

  /// 다크 모드 토글.
  IdentityVerificationScreenBuilder dark() {
    useDarkTheme();
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain b.errorRetry().dark()
    return this;
  }

  @override
  Widget build() {
    final overrides = <dynamic>[
      currentUserProvider.overrideWith((_) => _user),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      notificationInitializerProvider.overrideWith((_) {}),
      if (_consentRepository != null)
        consentRepositoryProvider.overrideWithValue(_consentRepository!),
    ];

    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: page,
      ),
    );
  }
}
