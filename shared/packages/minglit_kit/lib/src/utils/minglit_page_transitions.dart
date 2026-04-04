import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material 3 모션 전환 헬퍼.
///
/// [sharedAxisScaled]: 계층 네비게이션 전환 (Z축 SharedAxis).
/// [fadeThrough]: 동일 계층 전환 (FadeThrough).
class MinglitPageTransitions {
  /// Z축 SharedAxis — 계층 네비게이션용
  static CustomTransitionPage<T> sharedAxisScaled<T>({
    required LocalKey key,
    required Widget child,
  }) =>
      CustomTransitionPage<T>(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        ),
      );

  /// FadeThrough — 동일 계층 전환용
  static CustomTransitionPage<T> fadeThrough<T>({
    required LocalKey key,
    required Widget child,
  }) =>
      CustomTransitionPage<T>(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      );
}
