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
      scaffoldBackgroundColor: MinglitColors.background,
      // Layer 1: 텍스트 통일성 (Using local fontFamily 'NotoSansKR')
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          color: MinglitColors.textSecondary,
        ),
        // Fix #474: 빈 슬롯 채우기 — 하드코딩 fontSize 흡수
        bodySmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          color: MinglitColors.textSecondary,
        ),
        labelLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: MinglitColors.textPrimary,
        ),
        labelMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: MinglitColors.textPrimary,
        ),
        labelSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: MinglitColors.textPrimary,
        ),
      ),
      // Fix #474: ThemeExtension 등록
      extensions: const [MinglitTextThemeExtension.light],
      // Layer 2: 컴포넌트 테마 (see minglit_component_theme.dart)
      appBarTheme: _MinglitComponentThemes.appBar,
      elevatedButtonTheme: _MinglitComponentThemes.elevatedButton,
      outlinedButtonTheme: _MinglitComponentThemes.outlinedButton,
      textButtonTheme: _MinglitComponentThemes.textButton,
      cardTheme: _MinglitComponentThemes.card,
      inputDecorationTheme: _MinglitComponentThemes.inputDecoration,
      chipTheme: _MinglitComponentThemes.chip,
      checkboxTheme: _MinglitComponentThemes.checkbox,
      tabBarTheme: _MinglitComponentThemes.tabBar,
      dividerTheme: _MinglitComponentThemes.divider,
    );
  }

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
          color: MinglitColorsDark.textPrimary,
        ),
        titleLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MinglitColorsDark.textPrimary,
        ),
        titleMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: MinglitColorsDark.textPrimary,
        ),
        titleSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: MinglitColorsDark.textPrimary,
        ),
        bodyMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          color: MinglitColorsDark.textSecondary,
        ),
        // Fix #474: 빈 슬롯 채우기 — 하드코딩 fontSize 흡수
        bodySmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          color: MinglitColorsDark.textSecondary,
        ),
        labelLarge: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: MinglitColorsDark.textPrimary,
        ),
        labelMedium: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: MinglitColorsDark.textPrimary,
        ),
        labelSmall: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: MinglitColorsDark.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MinglitColorsDark.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: MinglitColorsDark.textPrimary),
        titleTextStyle: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          color: MinglitColorsDark.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansKR',
        ),
      ),
      elevatedButtonTheme: _MinglitComponentThemes.elevatedButton,
      outlinedButtonTheme: _MinglitComponentThemes.outlinedButton,
      textButtonTheme: _MinglitComponentThemes.textButton,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        elevation: 0,
        color: MinglitColorsDark.surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MinglitColorsDark.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          borderSide: const BorderSide(
            color: MinglitColorsDark.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(MinglitSpacing.medium),
        hintStyle: const TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          color: MinglitColorsDark.textSecondary,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
        backgroundColor: MinglitColorsDark.surface,
        secondarySelectedColor: MinglitColorsDark.primary,
        labelStyle: const TextStyle(
          fontSize: 13,
        ), // ignore: minglit_no_hardcoded_text_style -- theme definition
      ),
      checkboxTheme: _MinglitComponentThemes.checkbox,
      tabBarTheme: _MinglitComponentThemes.tabBar,
      dividerTheme: const DividerThemeData(
        color: MinglitColorsDark.divider,
        thickness: 1,
        space: MinglitSpacing.medium,
      ),
    );
  }
}
