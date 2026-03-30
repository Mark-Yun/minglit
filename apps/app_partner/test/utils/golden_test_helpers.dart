import 'dart:io';

import 'package:alchemist/alchemist.dart'
    show GoldenTestGroup, GoldenTestScenario, PumpAction, onlyPumpAndSettle;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

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

/// Creates a [PumpAction] that pumps the widget tree, then dumps the render
/// tree to a `.render.txt` file alongside the golden image.
///
/// The dump contains exact padding, sizes, and constraints for every
/// [RenderObject] — useful for automated spacing/alignment analysis.
Future<void> Function(WidgetTester) pumpAndDumpTree(String fileName) {
  return (WidgetTester tester) async {
    await onlyPumpAndSettle(tester);
    final dump = tester.binding.renderViews.first.toStringDeep();
    File('test/goldens/$fileName.render.txt').writeAsStringSync(dump);
  };
}
