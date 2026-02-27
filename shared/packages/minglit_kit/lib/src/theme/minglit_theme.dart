import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
          const SizedBox(width: 16),
          appBarLogo(height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
      backgroundColor: MinglitColors.background,
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
      backgroundColor: MinglitColors.background,
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
        displayLarge: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleLarge: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleMedium: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleSmall: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        bodyMedium: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
          fontSize: 16,
          color: MinglitColors.textSecondary,
        ),
      ),
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
}
