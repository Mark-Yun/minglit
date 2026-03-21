import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed surface size for golden tests (consistency across environments).
const goldenSurfaceSize = Size(400, 800);

/// Pumps [widget] inside a [MaterialApp] + [Scaffold] with a fixed size,
/// then compares against [goldenFileName].
///
/// Use [surfaceSize] to override the default 400x800 canvas.
/// Use [theme] to supply the app's real theme data.
/// Use [wrapper] to customise how the widget is placed in the scaffold.
Future<void> expectGolden(
  WidgetTester tester, {
  required Widget widget,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  ThemeData? theme,
  Widget Function(Widget child)? wrapper,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final body = wrapper != null ? wrapper(widget) : widget;

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(body: body),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFileName),
  );
}
