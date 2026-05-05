import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildSubject({
  required VoidCallback onPressed,
  Brightness brightness = Brightness.light,
  Duration? autoDismiss,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? MinglitTheme.materialThemeDark
          : MinglitTheme.materialTheme,
      home: MinglitConfirmationPage(
        title: '좋아요를 보냈어요',
        description: '서로 좋아요가 맞으면 결과 화면에서 알려드릴게요.',
        icon: Icons.check_rounded,
        tone: MinglitConfirmationTone.success,
        ctaLabel: '닫기',
        onPressed: onPressed,
        autoDismiss: autoDismiss,
      ),
    ),
  );
}

void main() {
  group('resolveMinglitConfirmationPalette', () {
    test('maps each tone to distinct base colors in light theme', () {
      expect(
        resolveMinglitConfirmationPalette(
          MinglitConfirmationTone.success,
          Brightness.light,
        ).iconColor,
        MinglitColors.success,
      );
      expect(
        resolveMinglitConfirmationPalette(
          MinglitConfirmationTone.primary,
          Brightness.light,
        ).iconColor,
        MinglitColors.primary,
      );
      expect(
        resolveMinglitConfirmationPalette(
          MinglitConfirmationTone.info,
          Brightness.light,
        ).iconColor,
        MinglitColors.info,
      );
      expect(
        resolveMinglitConfirmationPalette(
          MinglitConfirmationTone.warning,
          Brightness.light,
        ).iconColor,
        MinglitColors.warning,
      );
    });
  });

  testWidgets('invokes onPressed when CTA is tapped', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(_buildSubject(onPressed: () => pressed++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('닫기'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('autoDismiss triggers onPressed once after the timer', (
    tester,
  ) async {
    var pressed = 0;

    await tester.pumpWidget(
      _buildSubject(
        onPressed: () => pressed++,
        autoDismiss: const Duration(milliseconds: 300),
      ),
    );
    await tester.pump(const Duration(milliseconds: 299));
    expect(pressed, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(pressed, 1);

    await tester.tap(find.text('닫기'));
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('reduced motion shows the final state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(onPressed: () {}, disableAnimations: true),
    );

    expect(find.text('좋아요를 보냈어요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });
}
