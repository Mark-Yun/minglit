import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A scenario definition shared between golden tests and integration screenshot tests.
class ScreenshotScenario {
  const ScreenshotScenario({
    required this.name,
    required this.page,
    this.overrides = const [],
    this.brightness = Brightness.light,
    this.currentUser,
  });

  /// Unique name used as the screenshot/golden file name.
  final String name;

  /// The page widget to render.
  final Widget page;

  /// Riverpod provider overrides (same type as GoldenPageWrapper.overrides).
  final List<dynamic> overrides;

  /// Light or dark theme.
  final Brightness brightness;

  /// Optional current user (null = logged out).
  final User? currentUser;
}
