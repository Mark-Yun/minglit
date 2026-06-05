// PartnerLoginPageBuilder — partner_login_page 전용 fluent API.
//
// PartnerLoginPage 는 authControllerProvider 상태와 platform 분기(iOS/Android)에
// 따라 버튼 구성이 달라진다. MDS render에서는 auth 동작을 no-op으로 고정하고
// 상태별 UI만 deterministic 하게 재현한다.

import 'dart:async';

import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class _IdleAuthController extends AuthController {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> signInWithGoogle({String? redirectTo}) async {}

  @override
  Future<void> signInWithApple({String? redirectTo}) async {}

  @override
  Future<void> signInWithKakao({String? redirectTo}) async {}
}

class _LoadingAuthController extends AuthController {
  @override
  Future<void> build() => Completer<void>().future;
}

class _ErrorAuthController extends AuthController {
  @override
  FutureOr<void> build() {}
}

class _AuthErrorDialogSeed extends StatefulWidget {
  const _AuthErrorDialogSeed({required this.child});

  final Widget child;

  @override
  State<_AuthErrorDialogSeed> createState() => _AuthErrorDialogSeedState();
}

class _AuthErrorDialogSeedState extends State<_AuthErrorDialogSeed> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      handleMinglitError(
        context,
        Exception('render: forced auth error'),
        StackTrace.current,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PartnerLoginPageBuilder extends MdsScreenBuilder<PartnerLoginPage> {
  PartnerLoginPageBuilder() : super(page: const PartnerLoginPage());

  bool _isDevEnv = false;
  TargetPlatform _platform = TargetPlatform.iOS;
  AuthController Function() _controllerFactory = _IdleAuthController.new;
  bool _seedAuthErrorDialog = false;

  /// iOS/macOS/Web 대응 상태: Apple 버튼 포함 baseline.
  PartnerLoginPageBuilder iosDefault() {
    _platform = TargetPlatform.iOS;
    _controllerFactory = _IdleAuthController.new;
    _seedAuthErrorDialog = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// Android 대응 상태: Apple 버튼 미노출.
  PartnerLoginPageBuilder androidDefault() {
    _platform = TargetPlatform.android;
    _controllerFactory = _IdleAuthController.new;
    _seedAuthErrorDialog = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 인증 진행 중 전체 로딩 상태.
  PartnerLoginPageBuilder loading() {
    _platform = TargetPlatform.iOS;
    _controllerFactory = _LoadingAuthController.new;
    _seedAuthErrorDialog = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 인증 에러 상태.
  PartnerLoginPageBuilder error() {
    _platform = TargetPlatform.iOS;
    _controllerFactory = _ErrorAuthController.new;
    _seedAuthErrorDialog = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// Dev trigger 노출 여부.
  PartnerLoginPageBuilder devEnv({bool enabled = true}) {
    _isDevEnv = enabled;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    // PartnerLoginPage 내부 Apple 노출 분기에서 읽는 platform 고정.
    debugDefaultTargetPlatformOverride = _platform;

    final controllerFactory = _controllerFactory;
    final isDevEnv = _isDevEnv;
    final seedAuthErrorDialog = _seedAuthErrorDialog;
    final page = PartnerLoginPage(isDevEnvOverride: isDevEnv);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        authControllerProvider.overrideWith(controllerFactory),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        home: seedAuthErrorDialog ? _AuthErrorDialogSeed(child: page) : page,
      ),
    );
  }
}
