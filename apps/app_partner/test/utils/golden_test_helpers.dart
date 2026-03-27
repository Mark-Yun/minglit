import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fixed surface size for golden tests (consistency across environments).
const goldenSurfaceSize = Size(400, 800);

/// Pumps [widget] inside a [MaterialApp] + [Scaffold] with a fixed size,
/// then compares against [goldenFileName].
///
/// Use [surfaceSize] to override the default 400x800 canvas.
/// Use [brightness] to switch between light and dark theme.
Future<void> expectGolden(
  WidgetTester tester, {
  required Widget widget,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? MinglitTheme.materialThemeDark
          : MinglitTheme.materialTheme,
      home: Scaffold(body: Center(child: widget)),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFileName),
  );
}
