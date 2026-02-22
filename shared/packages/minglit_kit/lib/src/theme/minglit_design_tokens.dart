part of 'minglit_theme.dart';

/// Layer 3: 디자인 토큰 (Custom Constants)
/// 테마에 담기 애매한 수치들과 브랜드 색상을 상수로 관리합니다.
class MinglitColors {
  /// White background color.
  static const background = Color(0xFFFFFFFF);

  /// Primary brand purple.
  static const primary = Color(0xFF9900FF);

  /// Secondary amber accent.
  static const secondary = Color(0xFFFF9900); // Auxiliary 1

  /// Tertiary mint accent.
  static const tertiary = Color(0xFF48C9B0); // Toned down Mint

  /// Light surface background.
  static const surface = Color(0xFFF9FAFB); // 부드러운 회색 배경

  /// Error red color.
  static const error = Color(0xFFEF4444);

  /// Primary text color (near-black).
  static const textPrimary = Color(0xFF111827);

  /// Secondary text color (dark gray).
  static const textSecondary = Color(0xFF4B5563);
}

/// Spacing scale constants for consistent layout.
class MinglitSpacing {
  /// 2px extra-extra-small spacing.
  static const double xxsmall = 2;

  /// 4px extra-small spacing.
  static const double xsmall = 4;

  /// 8px small spacing.
  static const double small = 8;

  /// 16px medium spacing.
  static const double medium = 16;

  /// 24px large spacing.
  static const double large = 24;

  /// 32px extra-large spacing.
  static const double xlarge = 32;
}

/// Border radius constants for consistent rounding.
class MinglitRadius {
  /// 8px small border radius.
  static const double small = 8;

  /// 16px button border radius.
  static const double button = 16;

  /// 24px card border radius.
  static const double card = 24;

  /// 12px input border radius.
  static const double input = 12;
}

/// Icon size constants for consistent icon rendering.
class MinglitIconSize {
  /// 16px extra-small icon size.
  static const double xsmall = 16;

  /// 20px small icon size.
  static const double small = 20;

  /// 24px medium icon size.
  static const double medium = 24;

  /// 28px large icon size.
  static const double large = 28;

  /// 32px extra-large icon size.
  static const double xlarge = 32;
}

/// Animation duration constants.
class MinglitAnimation {
  /// 200ms fast animation duration.
  static const Duration fast = Duration(milliseconds: 200);

  /// 350ms medium animation duration.
  static const Duration medium = Duration(milliseconds: 350);

  /// 500ms slow animation duration.
  static const Duration slow = Duration(milliseconds: 500);
}
