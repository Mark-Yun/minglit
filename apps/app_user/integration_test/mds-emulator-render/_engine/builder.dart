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

// NOTE: List<dynamic> + .cast() 패턴은 의도된 선택 (style choice 아님).
// Riverpod 3.x 의 `Override` 와 `ProviderListenable` 는 sealed class /
// internal interface 로 public export 가 없어, 외부 코드가 직접 type 으로
// 사용 불가. ProviderScope.overrides 가 받는 type 자체가 internal `Override`.
// alchemist 의 GoldenPageWrapper 도 동일 우회 (List<dynamic>).
// 런타임 동작은 strict type 과 동일 — cast 가 실패 시 즉시 throw.
//
// ⚠ 함정 — provider override 중복:
// Riverpod 는 같은 provider 가 두 번 override 되면 build 시점에 throw
// ("Tried to override a provider twice"). 같은 provider 를 set 하는 fluent
// 메서드가 2개라면 (예: `empty()` 와 `withEvents()`) state setup 에서 한쪽만
// 호출하도록 author 가 책임진다. base 에 mutable provider 를 두지 않는 것이
// 안전한 default (모든 state 가 명시적 호출).

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
