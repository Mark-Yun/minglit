part of 'minglit_theme.dart';

/// Layer 3: 디자인 토큰 (Custom Constants)
/// 테마에 담기 애매한 수치들과 브랜드 색상을 상수로 관리합니다.
class MinglitColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF9900FF);
  static const secondary = Color(0xFFFF9900); // Auxiliary 1
  static const tertiary = Color(0xFF48C9B0); // Toned down Mint
  static const surface = Color(0xFFF9FAFB); // 부드러운 회색 배경
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
}

class MinglitSpacing {
  static const double xxsmall = 2;
  static const double xsmall = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double xlarge = 32;
}

class MinglitRadius {
  static const double small = 8;
  static const double button = 16;
  static const double card = 24;
  static const double input = 12;
}

class MinglitIconSize {
  static const double xsmall = 16;
  static const double small = 20;
  static const double medium = 24;
  static const double large = 28;
  static const double xlarge = 32;
}

class MinglitAnimation {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
}
