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
  _FakeVerificationManageController({
    this.fixedState,
    this.throwError = false,
  });

  // null → AsyncLoading (지연 반환으로 구현)
  final VerificationManageState? fixedState;
  final bool throwError;

  @override
  FutureOr<VerificationManageState> build() {
    if (throwError) {
      throw Exception('verification manage render error');
    }
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
  bool _throwError = false;
  bool _showArchiveDialog = false;
  int _initialTabIndex = 0;

  /// loading 상태 — MinglitAsyncValueWidget 로딩 스피너.
  VerificationManagePageBuilder loading() {
    _state = null;
    _throwError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// active list 비어 있음.
  VerificationManagePageBuilder withActiveEmpty() {
    _state = const VerificationManageState();
    _throwError = false;
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
    _throwError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// archived list 에 인증 1개 (active 비어있음).
  VerificationManagePageBuilder withArchivedItems() {
    _initialTabIndex = 1;
    _state = VerificationManageState(
      archived: [
        mockVerification(
          id: 'mock-verification-archived-1',
          displayName: '아카이브된 인증',
          isActive: false,
        ),
      ],
    );
    _throwError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// archived list 가 비어 있음.
  VerificationManagePageBuilder withArchivedEmpty() {
    _initialTabIndex = 1;
    _state = const VerificationManageState();
    _throwError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 오류 상태.
  VerificationManagePageBuilder error() {
    _throwError = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 보관 확인 다이얼로그.
  VerificationManagePageBuilder archiveDialog() {
    _state = VerificationManageState(active: [mockVerification()]);
    _showArchiveDialog = true;
    _throwError = false;
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
          () => _FakeVerificationManageController(
            fixedState: state,
            throwError: _throwError,
          ),
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
        home: _showArchiveDialog
            ? const _ArchiveDialogHarness(
                child: VerificationManagePage(),
              )
            : VerificationManagePage(initialTabIndex: _initialTabIndex),
      ),
    );
  }
}

class _ArchiveDialogHarness extends StatefulWidget {
  const _ArchiveDialogHarness({required this.child});

  final Widget child;

  @override
  State<_ArchiveDialogHarness> createState() => _ArchiveDialogHarnessState();
}

class _ArchiveDialogHarnessState extends State<_ArchiveDialogHarness> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        MinglitAlert.showConfirm(
          context: context,
          title: '인증 보관',
          content:
              "'입장 코드 인증' 인증을 보관함으로 이동하시겠습니까?\n\n"
              '더 이상 새로운 파티에 이 인증을 사용할 수 없게 됩니다.',
          confirmText: '보관하기',
          isDestructive: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
