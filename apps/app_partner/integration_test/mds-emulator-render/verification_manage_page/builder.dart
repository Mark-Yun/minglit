// VerificationManagePageBuilder — verification_manage_page 전용 fluent API.
//
// VerificationManagePage 는 verificationManageControllerProvider (async) 와
// verificationCoordinatorProvider 를 watch/read 한다.
// - controller: FutureOr<VerificationManageState> 반환 fake 사용
// - coordinator: no-op (navigation action 무시)

import 'dart:async';

import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_page.dart';
import 'package:app_partner/src/features/verification/verification_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

/// 고정 state 를 반환하는 fake controller.
class _FakeVerificationManageController extends VerificationManageController {
  _FakeVerificationManageController({this.fixedState});

  // null → AsyncLoading (지연 반환으로 구현)
  final VerificationManageState? fixedState;

  @override
  FutureOr<VerificationManageState> build() {
    final s = fixedState;
    if (s == null) {
      return Future<VerificationManageState>.delayed(
        const Duration(days: 1),
      );
    }
    return s;
  }
}

/// No-op coordinator — 화면 내 navigation 탭 없이 render 가능하게.
class _NoOpVerificationCoordinator extends VerificationCoordinator {
  @override
  void build() {}

  @override
  void pushVerificationManage() {}

  @override
  void pushCreateVerification({String? partnerId}) {}
}

class VerificationManagePageBuilder
    extends MdsScreenBuilder<VerificationManagePage> {
  VerificationManagePageBuilder() : super(page: const VerificationManagePage());

  VerificationManageState? _state; // null → loading
  Brightness _brightness = Brightness.light;

  /// loading 상태 — MinglitAsyncValueWidget 로딩 스피너.
  VerificationManagePageBuilder loading() {
    _state = null;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// active list 비어 있음.
  VerificationManagePageBuilder withActiveEmpty() {
    _state = const VerificationManageState();
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// active list 에 인증 2개.
  VerificationManagePageBuilder withActiveItems() {
    _state = VerificationManageState(
      active: [
        mockVerification(),
        mockVerification(
          id: 'mock-verification-2',
          displayName: '테니스 레이팅 인증',
          internalName: 'tennis_rating',
        ),
      ],
    );
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// archived list 에 인증 1개 (active 비어있음).
  VerificationManagePageBuilder withArchivedItems() {
    _state = VerificationManageState(
      archived: [
        mockVerification(
          id: 'mock-verification-archived-1',
          displayName: '아카이브된 인증',
          isActive: false,
        ),
      ],
    );
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  VerificationManagePageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final state = _state;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        verificationManageControllerProvider.overrideWith(
          () => _FakeVerificationManageController(fixedState: state),
        ),
        verificationCoordinatorProvider.overrideWith(
          _NoOpVerificationCoordinator.new,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const VerificationManagePage(),
      ),
    );
  }
}
