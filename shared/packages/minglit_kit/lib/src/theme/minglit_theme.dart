import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Layer 3: 디자인 토큰 (Custom Constants)
/// 테마에 담기 애매한 수치들과 브랜드 색상을 상수로 관리합니다.
class MinglitColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF9900FF);
  static const secondary = Color(0xFFFF9900); // Auxiliary 1
  static const tertiary = Color(0xFF21FFFE); // Auxiliary 2

  static const surface = Color(0xFFF9FAFB); // 부드러운 회색 배경
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
}

class MinglitSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double xlarge = 32;
}

class MinglitRadius {
  static const double button = 16;
  static const double card = 24;
  static const double input = 12;
}

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
    bool centerTitle = false,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: MinglitColors.background,
      surfaceTintColor: Colors.transparent,
    );
  }

  static ThemeData get materialTheme {
    final baseTextTheme = GoogleFonts.notoSansKrTextTheme();

    return ThemeData(
      useMaterial3: true,
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
      // Layer 1: 텍스트 통일성
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.notoSansKr(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        titleLarge: GoogleFonts.notoSansKr(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MinglitColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.notoSansKr(
          fontSize: 16,
          color: MinglitColors.textSecondary,
        ),
      ),

      // Layer 2: 컴포넌트 테마 - 앱바
      appBarTheme: const AppBarTheme(
        backgroundColor: MinglitColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: MinglitColors.textPrimary),
        titleTextStyle: TextStyle(
          color: MinglitColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Layer 2: 컴포넌트 테마 - 버튼
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MinglitColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Layer 2: 컴포넌트 테마 - 아웃라인 버튼
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MinglitColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          side: const BorderSide(color: MinglitColors.primary),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Layer 2: 컴포넌트 테마 - 텍스트 버튼
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MinglitColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Layer 2: 컴포넌트 테마 - 카드
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),

        elevation: 0,
        color: MinglitColors.surface,
        margin: EdgeInsets.zero,
      ),

      // Layer 2: 컴포넌트 테마 - 입력창
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MinglitColors.surface,
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
          borderSide: const BorderSide(color: MinglitColors.primary, width: 2),
        ),

        contentPadding: const EdgeInsets.all(MinglitSpacing.medium),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      ),

      // Chip 테마
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        side: BorderSide.none,
        backgroundColor: MinglitColors.surface,
        secondarySelectedColor: MinglitColors.primary,
        labelStyle: const TextStyle(fontSize: 13),
      ),

      // Checkbox 테마
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MinglitColors.primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: Colors.grey, width: 1.5),
      ),

      // Divider 테마
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB), // Gray-200
        thickness: 1,
        space: MinglitSpacing.medium,
      ),
    );
  }
}
