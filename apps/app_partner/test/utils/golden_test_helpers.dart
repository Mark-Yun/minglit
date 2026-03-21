import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed surface size for golden tests (consistency across environments).
const goldenSurfaceSize = Size(400, 800);

/// Pumps [widget] inside a [MaterialApp] + [Scaffold] with a fixed size,
/// then compares against [goldenFileName].
///
/// Use [surfaceSize] to override the default 400x800 canvas.
Future<void> expectGolden(
  WidgetTester tester, {
  required Widget widget,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(body: Center(child: widget)),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFileName),
  );
}
