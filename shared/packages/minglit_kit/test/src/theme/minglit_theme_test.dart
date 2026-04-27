import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mds/src/theme/minglit_theme.dart';

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

    // Fix #1218: AppBar 배경색이 scaffold 배경색과 일치해야 함
    test('light theme AppBar background matches scaffold background', () {
      final theme = MinglitTheme.materialTheme;

      expect(
        theme.appBarTheme.backgroundColor,
        equals(theme.scaffoldBackgroundColor),
        reason:
            'AppBar background should match scaffold background '
            '(both should be MinglitColors.surface)',
      );
    });

    test('light theme scaffold background is MinglitColors.surface', () {
      final theme = MinglitTheme.materialTheme;

      expect(theme.scaffoldBackgroundColor, equals(MinglitColors.surface));
    });

    group('dialog background', () {
      testWidgets('light theme uses the light dialog background color', (
        tester,
      ) async {
        Color? actualBackgroundColor;

        await tester.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                actualBackgroundColor = theme.dialogTheme.backgroundColor;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final theme = MinglitTheme.materialTheme;

        expect(actualBackgroundColor, MinglitColors.background);
        expect(theme.dialogTheme.backgroundColor, MinglitColors.background);
        expect(
          theme.dialogTheme.backgroundColor,
          theme.colorScheme.surface,
          reason:
              'Light dialog background should stay aligned with the light '
              'surface/background token.',
        );
      });

      testWidgets('dark theme uses surface #212121 instead of background', (
        tester,
      ) async {
        Color? actualBackgroundColor;

        await tester.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialThemeDark,
            home: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                actualBackgroundColor = theme.dialogTheme.backgroundColor;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final theme = MinglitTheme.materialThemeDark;

        expect(actualBackgroundColor, const Color(0xFF212121));
        expect(theme.dialogTheme.backgroundColor, const Color(0xFF212121));
        expect(theme.dialogTheme.backgroundColor, MinglitColorsDark.surface);
        expect(
          theme.dialogTheme.backgroundColor,
          isNot(const Color(0xFF0F0F0F)),
          reason:
              'Dark dialog background must not collapse into the app '
              'background layer.',
        );
        expect(
          theme.dialogTheme.backgroundColor,
          isNot(MinglitColorsDark.background),
        );
      });
    });
  });

  group('partnerTheme', () {
    test('uses MinglitPartnerColors.primary in colorScheme', () {
      final theme = MinglitTheme.partnerTheme;

      expect(theme.colorScheme.primary, MinglitPartnerColors.primary);
    });

    test('elevatedButton uses partner primary', () {
      final theme = MinglitTheme.partnerTheme;
      final style = theme.elevatedButtonTheme.style!;
      final bg = style.backgroundColor!.resolve({});

      expect(bg, MinglitPartnerColors.primary);
    });

    test('outlinedButton uses partner primary', () {
      final theme = MinglitTheme.partnerTheme;
      final style = theme.outlinedButtonTheme.style!;
      final fg = style.foregroundColor!.resolve({});
      final side = style.side!.resolve({})!;

      expect(fg, MinglitPartnerColors.primary);
      expect(side.color, MinglitPartnerColors.primary);
    });

    test('tabBar uses partner primary', () {
      final theme = MinglitTheme.partnerTheme;

      expect(theme.tabBarTheme.labelColor, MinglitPartnerColors.primary);
      expect(theme.tabBarTheme.indicatorColor, MinglitPartnerColors.primary);
    });
  });

  group('partnerThemeDark', () {
    test('uses MinglitPartnerColorsDark.primary in colorScheme', () {
      final theme = MinglitTheme.partnerThemeDark;

      expect(theme.colorScheme.primary, MinglitPartnerColorsDark.primary);
    });

    test('elevatedButton uses partner dark primary', () {
      final theme = MinglitTheme.partnerThemeDark;
      final bg = theme.elevatedButtonTheme.style!.backgroundColor!.resolve({});

      expect(bg, MinglitPartnerColorsDark.primary);
    });

    test('tabBar uses partner dark primary', () {
      final theme = MinglitTheme.partnerThemeDark;

      expect(theme.tabBarTheme.labelColor, MinglitPartnerColorsDark.primary);
      expect(
        theme.tabBarTheme.indicatorColor,
        MinglitPartnerColorsDark.primary,
      );
    });
  });

  group('dark theme AppBar consistency', () {
    // Fix #1218: dark theme은 변경하지 않았으므로 기존 일관성 유지 확인
    test('dark theme AppBar background matches scaffold background', () {
      final theme = MinglitTheme.materialThemeDark;

      expect(
        theme.appBarTheme.backgroundColor,
        equals(theme.scaffoldBackgroundColor),
        reason: 'Dark theme AppBar background should match scaffold background',
      );
    });
  });

  // Fix #1377: PNG → SVG 로고 교체 — 다크모드 자동 대응 회귀 테스트
  group('MinglitTheme.appBarLogo', () {
    testWidgets('light theme uses transparent background SVG asset', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Scaffold(body: MinglitTheme.appBarLogo()),
        ),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader.toString().contains(
                'minglit_logo_background_transparent.svg',
              ),
        ),
        findsOneWidget,
        reason: 'Light theme should use the transparent background SVG asset',
      );
    });

    // Fix #1467: 다크 테마에서도 통일된 단일 로고 asset 사용 — inverted 제거 회귀 테스트
    testWidgets(
      'dark theme uses the same transparent background SVG asset',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(body: MinglitTheme.appBarLogo()),
          ),
        );
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                widget.bytesLoader.toString().contains(
                  'minglit_logo_background_transparent.svg',
                ),
          ),
          findsOneWidget,
          reason:
              'Dark theme should use the same unified transparent SVG asset, '
              'not the removed inverted variant',
        );
      },
    );
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
