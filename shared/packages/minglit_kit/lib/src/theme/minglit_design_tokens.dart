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

  /// Success green color.
  static const success = Color(0xFF22C55E);

  /// Warning amber color.
  static const warning = Color(0xFFF59E0B);

  /// Fully transparent color.
  static const transparent = Color(0x00000000);

  /// Semi-transparent black scrim for overlays.
  static const scrim = Color(0x80000000);

  /// Glitch effect cyan — splash screen text shadow.
  static const glitchCyan = Color(0xFF21FFFE);

  /// Darker primary variant — splash gradient mid-tone.
  static const primaryDark = Color(0xFF7B2FBE);
}

class MinglitColorsDark {
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const background = Color(0xFF0F0F0F);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const surface = Color(0xFF212121);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const textPrimary = Color(0xFFFFFFFF);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const textSecondary = Color(0xFFAAAAAA);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const primary = Color(0xFFAA33FF);
  static const secondary = MinglitColors.secondary;
  static const tertiary = MinglitColors.tertiary;
  static const error = MinglitColors.error;
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const divider = Color(0xFF3D3D3D);
}

/// Spacing scale constants for consistent layout.
class MinglitSpacing {
  /// 0px zero spacing.
  static const double zero = 0;

  /// 2px extra-extra-small spacing.
  static const double xxsmall = 2;

  /// 4px extra-small spacing.
  static const double xsmall = 4;

  /// 6px extra-small-2 spacing.
  static const double xsmall2 = 6;

  /// 8px small spacing.
  static const double small = 8;

  /// 12px small-medium spacing.
  static const double sm = 12;

  /// 16px medium spacing.
  static const double medium = 16;

  /// 24px large spacing.
  static const double large = 24;

  /// 32px extra-large spacing.
  static const double xlarge = 32;

  /// 48px extra-extra-large spacing.
  static const double xxlarge = 48;

  /// 64px extra-extra-extra-large spacing.
  static const double xxxlarge = 64;

  // 시맨틱 토큰 (용도별)

  /// 16px screen edge padding (left/right).
  static const double screenEdge = 16;

  /// 12px gap between cards.
  static const double cardGap = 12;

  /// 16px card internal vertical padding.
  static const double cardContentV = 16;

  /// 4px title-to-body spacing.
  static const double titleToBody = 4;

  /// 40px section gap.
  static const double sectionGap = 40;
}

/// Border radius constants for consistent rounding.
class MinglitRadius {
  /// 8px small border radius.
  static const double small = 8;

  /// 12px button border radius.
  static const double button = 12;

  /// 16px card border radius.
  static const double card = 16;

  /// 12px input border radius.
  static const double input = 12;

  /// 100px chip border radius (fully rounded).
  static const double chip = 100;
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

  /// 40px extra-extra-large icon size.
  static const double xxlarge = 40;
}

/// Partner app brand colors — same purple family, toned down for business feel.
class MinglitPartnerColors {
  /// Primary brand indigo (toned-down purple).
  static const primary = Color(0xFF6C3CE1);

  /// Lighter variant for gradients.
  static const primaryLight = Color(0xFF8B5CF6);

  /// Surface tint for cards and containers.
  static const primarySurface = Color(0xFFF5F0FF);

  /// Border color for highlighted cards.
  static const primaryBorder = Color(0xFFE8E0FF);

  /// Container fill for secondary buttons.
  static const primaryContainer = Color(0xFFF0EDFF);
}

/// Partner app dark mode colors.
class MinglitPartnerColorsDark {
  // ignore: minglit_no_hardcoded_colors -- partner dark theme definition
  static const primary = Color(0xFF9B7BEC);
  // ignore: minglit_no_hardcoded_colors -- partner dark theme definition
  static const primaryLight = Color(0xFFB39DFF);
}

/// Animation duration constants.
class MinglitAnimation {
  /// 100ms micro animation duration for micro-interactions.
  static const Duration micro = Duration(milliseconds: 100);

  /// 200ms fast animation duration.
  static const Duration fast = Duration(milliseconds: 200);

  /// 350ms medium animation duration.
  static const Duration medium = Duration(milliseconds: 350);

  /// 500ms slow animation duration.
  static const Duration slow = Duration(milliseconds: 500);
}

/// Opacity constants for consistent transparency values.
class MinglitOpacity {
  /// 5% opacity — tint fill, selected card background.
  static const double tintFill = 0.05;

  /// 15% opacity — avatar placeholder background.
  static const double placeholder = 0.15;

  /// 20% opacity — unfilled gauge segments.
  static const double subtle = 0.2;

  /// 30% opacity — muted/empty elements.
  static const double muted = 0.3;

  /// 45% opacity — gradient overlay.
  static const double gradient = 0.45;

  /// 55% opacity — overlay backgrounds (badges, chips on images).
  static const double overlay = 0.55;

  /// 60% opacity — separator/divider text.
  static const double separator = 0.6;

  /// 80% opacity — light scrim.
  static const double scrimLight = 0.8;
}
