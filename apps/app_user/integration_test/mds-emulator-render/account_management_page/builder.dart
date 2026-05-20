// AccountManagementPageBuilder — account_management_page 전용 fluent API.
//
// AccountManagementPage 는 StatelessWidget (providers 없음) — props 로만 분기.
// build() 를 오버라이드해 상태 플래그에 따라 page 를 동적으로 생성.
//
// 기본 상태: user context · 본인인증 미완 (isVerified=false).

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class AccountManagementPageBuilder extends MdsScreenBuilder<Widget> {
  AccountManagementPageBuilder()
    : super(
        // page 는 build() 오버라이드에서 무시됨. type 충족용 placeholder.
        page: const SizedBox.shrink(),
      );

  bool _isVerified = false;
  bool _isPartnerMode = false;
  Brightness _brightness = Brightness.light;

  /// 본인인증 완료 상태 (isVerified=true).
  AccountManagementPageBuilder verified() {
    _isVerified = true;
    // ignore: avoid_returning_this, fluent builder — callers chain b.verified().dark()
    return this;
  }

  /// 파트너 앱 모드 — onPartnerProfile 제공, onCertification 없음.
  AccountManagementPageBuilder partnerMode() {
    _isPartnerMode = true;
    // ignore: avoid_returning_this, fluent builder — callers chain b.verified().dark()
    return this;
  }

  /// 다크 모드 토글.
  AccountManagementPageBuilder dark() {
    useDarkTheme();
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain b.verified().dark()
    return this;
  }

  @override
  Widget build() {
    final page = AccountManagementPage(
      onLogout: () {},
      onDeleteAccount: () {},
      onCertification: _isPartnerMode ? null : () {},
      onPartnerProfile: _isPartnerMode ? () {} : null,
      isVerified: _isVerified,
    );

    // AccountManagementPage 는 providers 를 쓰지 않으므로 공통 root override 만 주입.
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
      ].cast(),
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
