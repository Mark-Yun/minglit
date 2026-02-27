part of 'minglit_theme.dart';

/// Layer 2: 컴포넌트별 테마 정의
class _MinglitComponentThemes {
  static AppBarTheme get appBar => const AppBarTheme(
    backgroundColor: MinglitColors.background,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: MinglitColors.textPrimary),
    titleTextStyle: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
      color: MinglitColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'NotoSansKR',
    ),
  );

  static ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: MinglitColors.primary,
      foregroundColor: Colors.white, // ignore: minglit_no_hardcoded_colors -- theme definition
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      elevation: 0,
      textStyle: const TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: MinglitColors.primary,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      side: const BorderSide(color: MinglitColors.primary),
      textStyle: const TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static TextButtonThemeData get textButton => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: MinglitColors.primary,
      textStyle: const TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static CardThemeData get card => CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MinglitRadius.card),
    ),
    elevation: 0,
    color: MinglitColors.surface,
    margin: EdgeInsets.zero,
  );

  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
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
    hintStyle: const TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
      color: MinglitColors.textSecondary,
      fontSize: 14,
    ),
  );

  static ChipThemeData get chip => ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    ),
    side: BorderSide.none,
    backgroundColor: MinglitColors.surface,
    secondarySelectedColor: MinglitColors.primary,
    labelStyle: const TextStyle(fontSize: 13), // ignore: minglit_no_hardcoded_text_style -- theme definition
  );

  static CheckboxThemeData get checkbox => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return MinglitColors.primary;
      }
      return null;
    }),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    side: const BorderSide(color: Colors.grey, width: 1.5), // ignore: minglit_no_hardcoded_colors -- theme definition
  );

  static TabBarThemeData get tabBar => const TabBarThemeData(
    labelColor: MinglitColors.primary,
    unselectedLabelColor: MinglitColors.textSecondary,
    indicatorColor: MinglitColors.primary,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
    labelStyle: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: 'NotoSansKR',
    ),
    unselectedLabelStyle: TextStyle( // ignore: minglit_no_hardcoded_text_style -- theme definition
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'NotoSansKR',
    ),
  );

  static DividerThemeData get divider => const DividerThemeData(
    color: Color(0xFFE5E7EB), // ignore: minglit_no_hardcoded_colors -- theme definition
    thickness: 1,
    space: MinglitSpacing.medium,
  );
}
