import 'package:alchemist/alchemist.dart'
    show GoldenTestGroup, GoldenTestScenario;
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../scenarios/partner_screenshot_scenario.dart';
import 'partner_golden_test_helpers.dart' show PartnerGoldenPageWrapper;

/// Fixed surface size for golden tests (consistency across environments).
const goldenSurfaceSize = Size(400, 800);

/// Wraps a component widget in [MaterialApp] + [Scaffold] for Alchemist
/// [GoldenTestScenario] use. Unlike page wrappers, this is for standalone
/// components that don't need [ProviderScope].
///
/// Includes explicit size constraints to prevent infinite-size errors
/// inside [GoldenTestGroup]'s Table layout.
class GoldenComponentWrapper extends StatelessWidget {
  const GoldenComponentWrapper({
    required this.child,
    this.brightness = Brightness.light,
    this.width = 400,
    this.height = 800,
    super.key,
  });

  final Widget child;
  final Brightness brightness;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario → GoldenTestScenario conversion
// ---------------------------------------------------------------------------

extension PartnerScreenshotScenarioX on PartnerScreenshotScenario {
  /// Converts a [PartnerScreenshotScenario] into an Alchemist
  /// [GoldenTestScenario]. Component scenarios (isComponent == true) are
  /// rendered with [GoldenComponentWrapper]; page scenarios are rendered with
  /// [PartnerGoldenPageWrapper] sized at 390×844.
  GoldenTestScenario toGoldenTestScenario() {
    if (isComponent) {
      return GoldenTestScenario(
        name: name,
        child: GoldenComponentWrapper(
          brightness: brightness,
          child: page,
        ),
      );
    }
    return GoldenTestScenario(
      name: name,
      child: SizedBox(
        width: 390,
        height: 844,
        child: PartnerGoldenPageWrapper(
          page: page,
          overrides: overrides,
          brightness: brightness,
        ),
      ),
    );
  }
}
