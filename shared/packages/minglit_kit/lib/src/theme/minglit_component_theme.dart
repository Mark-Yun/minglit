part of 'minglit_theme.dart';

/// Layer 2: 컴포넌트별 테마 정의
class _MinglitComponentThemes {
  static AppBarTheme appBar(MinglitColorSet c) => AppBarTheme(
    backgroundColor: c.background,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: c.textPrimary),
    titleTextStyle: TextStyle(
      // ignore: minglit_no_hardcoded_text_style -- theme definition
      color: c.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'Pretendard',
    ),
  );

  static ElevatedButtonThemeData elevatedButton(MinglitColorSet c) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
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

  static OutlinedButtonThemeData outlinedButton(MinglitColorSet c) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          side: BorderSide(color: c.primary),
          textStyle: const TextStyle(
            // ignore: minglit_no_hardcoded_text_style -- theme definition
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static TextButtonThemeData textButton(MinglitColorSet c) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(
            // ignore: minglit_no_hardcoded_text_style -- theme definition
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static CardThemeData card(MinglitColorSet c) => CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MinglitRadius.card),
    ),
    elevation: 0,
    color: c.surface,
    margin: EdgeInsets.zero,
  );

  static InputDecorationTheme inputDecoration(MinglitColorSet c) =>
      InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
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
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(MinglitSpacing.medium),
        hintStyle: TextStyle(
          // ignore: minglit_no_hardcoded_text_style -- theme definition
          color: c.textSecondary,
          fontSize: 14,
        ),
      );

  static ChipThemeData chip(MinglitColorSet c) => ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MinglitRadius.chip),
    ),
    side: BorderSide.none,
    backgroundColor: c.surface,
    secondarySelectedColor: c.primary,
    labelStyle: const TextStyle(
      fontSize: 13,
    ), // ignore: minglit_no_hardcoded_text_style -- theme definition
  );

  static CheckboxThemeData checkbox(MinglitColorSet c) => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return c.primary;
      }
      return null;
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    side: BorderSide(
      color: c.textSecondary.withValues(alpha: MinglitOpacity.strong),
      width: 1.5,
    ),
  );

  static TabBarThemeData tabBar(MinglitColorSet c) => TabBarThemeData(
    labelColor: c.primary,
    unselectedLabelColor: c.textSecondary,
    indicatorColor: c.primary,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
    labelStyle: const TextStyle(
      // ignore: minglit_no_hardcoded_text_style -- theme definition
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: 'Pretendard',
    ),
    unselectedLabelStyle: const TextStyle(
      // ignore: minglit_no_hardcoded_text_style -- theme definition
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Pretendard',
    ),
  );

  static DividerThemeData divider(MinglitColorSet c) => DividerThemeData(
    color: c.divider,
    thickness: 1,
    space: MinglitSpacing.medium,
  );
}
