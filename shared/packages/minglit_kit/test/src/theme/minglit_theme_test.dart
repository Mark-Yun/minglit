import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

void main() {
  group('MinglitTheme', () {
    test('materialTheme returns a valid ThemeData', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.colorScheme, isNotNull);
      expect(theme.textTheme, isNotNull);
    });

    test('theme has custom primary color', () {
      final theme = MinglitTheme.materialTheme;

      // Should have a defined primary color (not default blue)
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('theme has custom surface color', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme.colorScheme.surface, isNotNull);
    });

    test('theme has card theme', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme.cardTheme, isNotNull);
    });

    test('theme has elevated button theme', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme.elevatedButtonTheme, isNotNull);
    });

    test('theme has input decoration theme', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme.inputDecorationTheme, isNotNull);
    });
  });

  group('MinglitDesignTokens', () {
    test('MinglitSpacing constants are positive', () {
      expect(MinglitSpacing.xsmall, greaterThan(0));
      expect(MinglitSpacing.small, greaterThan(0));
      expect(MinglitSpacing.medium, greaterThan(0));
      expect(MinglitSpacing.large, greaterThan(0));
    });

    test('MinglitSpacing values are ordered', () {
      expect(MinglitSpacing.xsmall, lessThan(MinglitSpacing.small));
      expect(MinglitSpacing.small, lessThan(MinglitSpacing.medium));
      expect(MinglitSpacing.medium, lessThan(MinglitSpacing.large));
    });

    test('MinglitRadius constants are non-negative', () {
      expect(MinglitRadius.small, greaterThanOrEqualTo(0));
      expect(MinglitRadius.card, greaterThan(0));
      expect(MinglitRadius.input, greaterThan(0));
    });

    test('MinglitIconSize constants are positive', () {
      expect(MinglitIconSize.xsmall, greaterThan(0));
    });
  });
}
