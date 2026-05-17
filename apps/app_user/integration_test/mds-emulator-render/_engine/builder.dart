// MdsScreenBuilder<W> — 화면별 fluent API base.
//
// 각 화면은 본 클래스를 extend 하여 자기 특화 메서드를 fluent 로 제공.
// 예: HomePageBuilder().withEvents(3).dark()
//
// build() 호출 시 ProviderScope + MaterialApp 로 wrap 된 위젯 반환.
// 모든 화면 공통 override (currentUser, authStateChanges, notificationInitializer)
// 는 _commonRootOverrides() 가 자동 주입.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/minglit_kit.dart';

// NOTE: List<Override> 대신 List<dynamic> + .cast() 패턴 사용 — Riverpod 의
// Override 타입이 외부 import 가 까다로워서 (alchemist 의 GoldenPageWrapper
// 와 동일 우회). 런타임엔 동일.

/// 모든 화면이 공유하는 root level override.
List<dynamic> _commonRootOverrides() => [
      currentUserProvider.overrideWith((_) => null),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      notificationInitializerProvider.overrideWith((_) {}),
    ];

/// 화면별 builder 의 base class.
///
/// 화면 특화 builder 는 본 클래스를 extend 하고 fluent 메서드를 추가:
/// ```dart
/// class HomePageBuilder extends MdsScreenBuilder<HomePage> {
///   HomePageBuilder() : super(
///     page: const HomePage(),
///     base: [homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator())],
///   );
///
///   HomePageBuilder withEvents(int n) {
///     addOverride(recommendationFeedProvider.overrideWith(...));
///     return this;
///   }
/// }
/// ```
abstract class MdsScreenBuilder<W extends Widget> {
  MdsScreenBuilder({
    required this.page,
    List<dynamic> base = const [],
  }) : _base = List.unmodifiable(base);

  final W page;
  final List<dynamic> _base;
  final List<dynamic> _stateOverrides = [];
  Brightness _brightness = Brightness.light;

  /// state 전용 override 추가. 화면 특화 builder 의 fluent 메서드에서 사용.
  @protected
  void addOverride(dynamic o) => _stateOverrides.add(o);

  /// 다크 모드 토글. 모든 builder 가 공통으로 가짐.
  void useDarkTheme() {
    _brightness = Brightness.dark;
  }

  /// 최종 위젯 트리 생성.
  /// `commonRoot + base + state` 순으로 override 적용.
  /// 같은 provider 가 여러 번 override 되면 후순위가 이김.
  Widget build() {
    return ProviderScope(
      overrides: [
        ..._commonRootOverrides().cast(),
        ..._base.cast(),
        ..._stateOverrides.cast(),
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
