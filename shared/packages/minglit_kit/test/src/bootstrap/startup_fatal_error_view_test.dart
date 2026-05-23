import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('StartupFatalErrorView renders MDS error state and retry', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: StartupFatalErrorView(
          error: StateError('missing env'),
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.text('앱을 시작할 수 없습니다'), findsOneWidget);
    expect(find.textContaining('missing env'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    expect(retryCount, 1);
  });

  testWidgets('StartupFatalErrorView hides details when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: StartupFatalErrorView(
          error: StateError('missing env'),
          showDetails: false,
        ),
      ),
    );

    expect(find.text('앱을 시작할 수 없습니다'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('missing env'), findsNothing);
  });
}
