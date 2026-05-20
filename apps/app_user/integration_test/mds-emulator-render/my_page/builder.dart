// MyPageBuilder — my_page 전용 fluent API.
//
// 기본 상태: 비로그인 (currentUserProvider = null).
// authenticated() 호출 시 minglit_demo 의 demoUser 로 교체.
//
// _commonRootOverrides() 의 currentUserProvider 중복 override 방지를 위해
// build() 를 직접 override 함 (AccountManagementPageBuilder 패턴).

import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/logic/auth_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_demo/minglit_demo.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class MyPageBuilder extends MdsScreenBuilder<MyPage> {
  MyPageBuilder()
    : super(
        page: const MyPage(),
        base: [
          homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
          authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
        ],
      );

  bool _isAuthenticated = false;
  Brightness _brightness = Brightness.light;

  /// 로그인 상태 — currentUserProvider 를 demoUser 로 교체.
  MyPageBuilder authenticated() {
    _isAuthenticated = true;
    // ignore: avoid_returning_this, fluent builder — callers chain b.authenticated().dark()
    return this;
  }

  /// 다크 모드 토글.
  MyPageBuilder dark() {
    useDarkTheme();
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain b.authenticated().dark()
    return this;
  }

  @override
  Widget build() {
    final userOverride = _isAuthenticated
        ? currentUserProvider.overrideWith((_) => demoUser)
        : currentUserProvider.overrideWith((_) => null);

    return ProviderScope(
      overrides: [
        userOverride,
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
        authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
      ],
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
