import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:minglit_kit/src/theme/minglit_text_theme_extension.dart';

part 'minglit_design_tokens.dart';
part 'minglit_design_utils.dart';
part 'minglit_component_theme.dart';
part 'minglit_quill_theme.dart';

/// Layer 1 & 2: 기본 테마 및 컴포넌트 테마

class MinglitTheme {
  /// App Bar Logo Widget
  static Widget appBarLogo({double height = 32}) {
    return Image.asset(
      'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// Scroll-to-hide AppBar (SliverAppBar)
  static Widget sliverAppBar({
    required String title,
    List<Widget>? actions,
    bool floating = true,
    bool snap = true,
  }) {
    return SliverAppBar(
      floating: floating,
      snap: snap,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: MinglitSpacing.medium),
          appBarLogo(height: 36),
          const SizedBox(width: MinglitSpacing.sm),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Standard AppBar with title and optional actions.
  static PreferredSizeWidget simpleAppBar({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    bool showBackButton = true,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      surfaceTintColor: Colors.transparent,
    );
  }

  static ThemeData get materialTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: MinglitColors.primary,
        primary: MinglitColors.primary,
        secondary: MinglitColors.secondary,
        tertiary: MinglitColors.tertiary,
        surface: MinglitColors.background,
        error: MinglitColors.error,
        onSurfaceVariant: MinglitColors.textSecondary,
      ),
      scaffoldBackgroundColor: MinglitColors.surface,
      // Layer 1: 텍스트 통일성 (Using local fontFamily 'NotoSansKR')
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.25,
          color: MinglitColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.33,
          color: MinglitColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.29,
          color: MinglitColors.textPrimary,
        ),
        titleLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
          color: MinglitColors.textPrimary,
        ),
        titleMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.5,
          color: MinglitColors.textPrimary,
        ),
        titleSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.43,
          color: MinglitColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 18,
          height: 1.33,
          color: MinglitColors.textSecondary,
        ),
        bodyMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          height: 1.5,
          color: MinglitColors.textSecondary,
        ),
        // Fix #568: bodySmall 12→13, height 추가
        bodySmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 13,
          height: 1.5,
          color: MinglitColors.textSecondary,
        ),
        // Fix #474: 빈 슬롯 채우기 — 하드코딩 fontSize 흡수
        labelLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.43,
          color: MinglitColors.textPrimary,
        ),
        labelMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: MinglitColors.textPrimary,
        ),
        labelSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: MinglitColors.textPrimary,
        ),
      ),
      // Fix #474: ThemeExtension 등록
      extensions: const [MinglitTextThemeExtension.light],
      // Layer 2: 컴포넌트 테마 (see minglit_component_theme.dart)
      appBarTheme: _MinglitComponentThemes.appBar(MinglitColorSet.light),
      elevatedButtonTheme: _MinglitComponentThemes.elevatedButton(MinglitColorSet.light),
      outlinedButtonTheme: _MinglitComponentThemes.outlinedButton(MinglitColorSet.light),
      textButtonTheme: _MinglitComponentThemes.textButton(MinglitColorSet.light),
      cardTheme: _MinglitComponentThemes.card(MinglitColorSet.light),
      inputDecorationTheme: _MinglitComponentThemes.inputDecoration(MinglitColorSet.light),
      chipTheme: _MinglitComponentThemes.chip(MinglitColorSet.light),
      checkboxTheme: _MinglitComponentThemes.checkbox(MinglitColorSet.light),
      tabBarTheme: _MinglitComponentThemes.tabBar(MinglitColorSet.light),
      dividerTheme: _MinglitComponentThemes.divider(MinglitColorSet.light),
    );
  }

  /// Partner app light theme — same structure, different primary color.
  static ThemeData get partnerTheme {
    final base = materialTheme;
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MinglitPartnerColors.primary,
        primary: MinglitPartnerColors.primary,
        secondary: MinglitColors.secondary,
        tertiary: MinglitColors.tertiary,
        surface: MinglitColors.background,
        error: MinglitColors.error,
        onSurfaceVariant: MinglitColors.textSecondary,
      ),
      elevatedButtonTheme: _partnerElevatedButton(MinglitPartnerColors.primary),
      outlinedButtonTheme: _partnerOutlinedButton(MinglitPartnerColors.primary),
      textButtonTheme: _partnerTextButton(MinglitPartnerColors.primary),
      // inputDecorationTheme: skipped — InputDecorationTheme.copyWith returns
      // InputDecorationThemeData which is incompatible with ThemeData.copyWith
      // in Flutter 3.41+. The focusedBorder uses colorScheme.primary via M3.
      tabBarTheme: _partnerTabBar(
        MinglitPartnerColors.primary,
        base.tabBarTheme,
      ),
      chipTheme: base.chipTheme.copyWith(
        secondarySelectedColor: MinglitPartnerColors.primary,
      ),
      checkboxTheme: _partnerCheckbox(MinglitPartnerColors.primary),
    );
  }

  /// Partner app dark theme.
  static ThemeData get partnerThemeDark {
    final base = materialThemeDark;
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MinglitPartnerColorsDark.primary,
        brightness: Brightness.dark,
        primary: MinglitPartnerColorsDark.primary,
        secondary: MinglitColorsDark.secondary,
        tertiary: MinglitColorsDark.tertiary,
        surface: MinglitColorsDark.surface,
        error: MinglitColorsDark.error,
        onSurfaceVariant: MinglitColorsDark.textSecondary,
      ),
      elevatedButtonTheme: _partnerElevatedButton(
        MinglitPartnerColorsDark.primary,
      ),
      outlinedButtonTheme: _partnerOutlinedButton(
        MinglitPartnerColorsDark.primary,
      ),
      textButtonTheme: _partnerTextButton(MinglitPartnerColorsDark.primary),
      // inputDecorationTheme: skipped — same Flutter 3.41+ type issue.
      tabBarTheme: _partnerTabBar(
        MinglitPartnerColorsDark.primary,
        base.tabBarTheme,
      ),
      chipTheme: base.chipTheme.copyWith(
        secondarySelectedColor: MinglitPartnerColorsDark.primary,
      ),
      checkboxTheme: _partnerCheckbox(MinglitPartnerColorsDark.primary),
    );
  }

  // -- Partner component theme helpers --

  static ElevatedButtonThemeData _partnerElevatedButton(Color primary) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors
              .white, // ignore: minglit_no_hardcoded_colors -- theme definition
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            // ignore: minglit_no_hardcoded_text_style -- theme definition
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static OutlinedButtonThemeData _partnerOutlinedButton(Color primary) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          side: BorderSide(color: primary),
          textStyle: const TextStyle(
            // ignore: minglit_no_hardcoded_text_style -- theme definition
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static TextButtonThemeData _partnerTextButton(Color primary) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            // ignore: minglit_no_hardcoded_text_style -- theme definition
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static TabBarThemeData _partnerTabBar(Color primary, TabBarThemeData base) =>
      base.copyWith(labelColor: primary, indicatorColor: primary);

  static CheckboxThemeData _partnerCheckbox(Color primary) => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return primary;
      return null;
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    side: const BorderSide(
      color: Colors.grey,
      width: 1.5,
    ), // ignore: minglit_no_hardcoded_colors -- theme definition
  );

  static ThemeData get materialThemeDark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: MinglitColorsDark.primary,
        brightness: Brightness.dark,
        primary: MinglitColorsDark.primary,
        secondary: MinglitColorsDark.secondary,
        tertiary: MinglitColorsDark.tertiary,
        surface: MinglitColorsDark.surface,
        error: MinglitColorsDark.error,
        onSurfaceVariant: MinglitColorsDark.textSecondary,
      ),
      scaffoldBackgroundColor: MinglitColorsDark.background,
      // Fix #474: ThemeExtension 등록
      extensions: const [MinglitTextThemeExtension.dark],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.25,
          color: MinglitColorsDark.textPrimary,
        ),
        headlineSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.33,
          color: MinglitColorsDark.textPrimary,
        ),
        headlineMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.29,
          color: MinglitColorsDark.textPrimary,
        ),
        titleLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
          color: MinglitColorsDark.textPrimary,
        ),
        titleMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.5,
          color: MinglitColorsDark.textPrimary,
        ),
        titleSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.43,
          color: MinglitColorsDark.textPrimary,
        ),
        bodyLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 18,
          height: 1.33,
          color: MinglitColorsDark.textSecondary,
        ),
        bodyMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          height: 1.5,
          color: MinglitColorsDark.textSecondary,
        ),
        // Fix #568: bodySmall 12→13, height 추가
        bodySmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 13,
          height: 1.5,
          color: MinglitColorsDark.textSecondary,
        ),
        // Fix #474: 빈 슬롯 채우기 — 하드코딩 fontSize 흡수
        labelLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.43,
          color: MinglitColorsDark.textPrimary,
        ),
        labelMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: MinglitColorsDark.textPrimary,
        ),
        labelSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: MinglitColorsDark.textPrimary,
        ),
      ),
      appBarTheme: _MinglitComponentThemes.appBar(MinglitColorSet.dark),
      elevatedButtonTheme: _MinglitComponentThemes.elevatedButton(MinglitColorSet.dark),
      outlinedButtonTheme: _MinglitComponentThemes.outlinedButton(MinglitColorSet.dark),
      textButtonTheme: _MinglitComponentThemes.textButton(MinglitColorSet.dark),
      cardTheme: _MinglitComponentThemes.card(MinglitColorSet.dark),
      inputDecorationTheme: _MinglitComponentThemes.inputDecoration(MinglitColorSet.dark),
      chipTheme: _MinglitComponentThemes.chip(MinglitColorSet.dark),
      checkboxTheme: _MinglitComponentThemes.checkbox(MinglitColorSet.dark),
      tabBarTheme: _MinglitComponentThemes.tabBar(MinglitColorSet.dark),
      dividerTheme: _MinglitComponentThemes.divider(MinglitColorSet.dark),
    );
  }
}
