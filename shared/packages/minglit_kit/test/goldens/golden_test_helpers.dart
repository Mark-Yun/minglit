import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fixed surface size for golden tests (iPhone 14 ratio).
const goldenSurfaceSize = Size(390, 844);

/// Pumps [widget] inside a [MaterialApp] + [Scaffold] with a fixed size,
/// then compares against [goldenFileName].
///
/// Use [surfaceSize] to override the default 390×844 canvas.
/// Use [brightness] to switch between light and dark theme.
/// Set [settle] to false for widgets with infinite animations (e.g. shimmer).
Future<void> expectGolden(
  WidgetTester tester, {
  required Widget widget,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  Brightness brightness = Brightness.light,
  bool settle = true,
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFileName),
  );
}
