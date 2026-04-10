import 'package:flutter/material.dart';

/// A scenario definition shared between golden tests and integration screenshot tests.
class PartnerScreenshotScenario {
  const PartnerScreenshotScenario({
    required this.name,
    required this.page,
    this.overrides = const [],
    this.brightness = Brightness.light,
    this.isComponent = false,
  });

  /// Unique name used as the screenshot/golden file name.
  final String name;

  /// The page widget to render.
  final Widget page;

  /// Riverpod provider overrides (same type as PartnerGoldenPageWrapper.overrides).
  final List<dynamic> overrides;

  /// Light or dark theme.
  final Brightness brightness;

  /// True for component-level tests (rendered with GoldenComponentWrapper),
  /// false for full-page tests (rendered with PartnerGoldenPageWrapper).
  final bool isComponent;
}
