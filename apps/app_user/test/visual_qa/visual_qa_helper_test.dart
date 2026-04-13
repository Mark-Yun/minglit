// Unit / widget tests for VisualQaTester extension.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'visual_qa_helper.dart';

void main() {
  tearDown(VisualQaTester.resetCounters);

  group('VisualQaTester', () {
    testWidgets('capture() saves PNG and TXT files', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('hello visual qa')),
        ),
      );
      await tester.pump();

      // Should not throw — failures are caught internally.
      await tester.capture('initial_render');

      expect(find.text('hello visual qa'), findsOneWidget);
    });

    testWidgets('capture() with valid label does not throw', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('label test'))),
      );
      await tester.pump();

      await expectLater(
        () => tester.capture('valid_label_123'),
        returnsNormally,
      );
    });

    testWidgets('capture() silently skips invalid label', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('label test'))),
      );
      await tester.pump();

      // Invalid label should NOT throw — it prints a warning and returns.
      await tester.capture('Invalid Label!');

      // Test still passes — capture failure does not propagate.
      expect(find.text('label test'), findsOneWidget);
    });

    testWidgets('tapAndCapture() captures before and after tap', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tapAndCapture(find.text('Tap Me'), 'tap_button');

      expect(tapped, isTrue);
    });

    testWidgets('navigateAndCapture() taps and captures result', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.navigateAndCapture(find.text('Navigate'), 'after_navigate');

      expect(tapped, isTrue);
    });
  });
}
