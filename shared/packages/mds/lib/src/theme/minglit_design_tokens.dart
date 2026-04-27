part of 'minglit_theme.dart';

/// Layer 3: 디자인 토큰 (Custom Constants)
/// 테마에 담기 애매한 수치들과 브랜드 색상을 상수로 관리합니다.
class MinglitColors {
  /// White background color.
  static const background = Color(MdsTokens.colorBackground);

  /// Primary brand purple.
  static const primary = Color(MdsTokens.colorPrimary);

  /// Secondary amber accent.
  static const secondary = Color(MdsTokens.colorSecondary); // Auxiliary 1

  /// Tertiary mint accent.
  static const tertiary = Color(MdsTokens.colorTertiary); // Toned down Mint

  /// Light surface background.
  static const surface = Color(MdsTokens.colorSurface); // 부드러운 회색 배경

  /// Error red color.
  static const error = Color(MdsTokens.colorError);

  /// Primary text color (near-black).
  static const textPrimary = Color(MdsTokens.colorTextPrimary);

  /// Secondary text color (dark gray).
  static const textSecondary = Color(MdsTokens.colorTextSecondary);

  /// Success green color (green-600 for better contrast vs white).
  static const success = Color(MdsTokens.colorSuccess);

  /// Info blue color — neutral informational state (e.g. pending payment).
  // Fix #1236: 상태 배지 의미론적 색상 — 결제대기 등 중립 정보 상태
  static const info = Color(MdsTokens.colorInfo);

  /// Warning amber color (amber-600 for better contrast vs white).
  static const warning = Color(MdsTokens.colorWarning);

  /// Fully transparent color.
  // TODO(mds-tokens): add colorTransparent to tokens.json and migrate
  static const transparent = Color(0x00000000);

  /// Light theme border/divider separator color.
  static const divider = Color(
    MdsTokens.colorDivider,
  ); // ignore: minglit_no_hardcoded_colors -- light divider token

  /// Semi-transparent black scrim for overlays.
  static const scrim = Color(MdsTokens.colorScrim);

  /// Glitch effect cyan — splash screen text shadow.
  static const glitchCyan = Color(MdsTokens.colorGlitchCyan);

  /// Darker primary variant — splash gradient mid-tone.
  static const primaryDark = Color(MdsTokens.colorPrimaryDark);
}

class MinglitColorsDark {
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const background = Color(MdsTokens.colorDarkBackground);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const surface = Color(MdsTokens.colorDarkSurface);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const textPrimary = Color(MdsTokens.colorDarkTextPrimary);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const textSecondary = Color(MdsTokens.colorDarkTextSecondary);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const primary = Color(MdsTokens.colorDarkPrimary);
  static const Color secondary = MinglitColors.secondary;
  static const Color tertiary = MinglitColors.tertiary;
  static const Color error = MinglitColors.error;
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const success = Color(MdsTokens.colorDarkSuccess);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const info = Color(MdsTokens.colorDarkInfo);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const warning = Color(MdsTokens.colorDarkWarning);
  // ignore: minglit_no_hardcoded_colors -- dark theme definition
  static const divider = Color(MdsTokens.colorDarkDivider);
}

/// 컴포넌트 테마에서 사용하는 색상 세트.
/// Light/Dark 모드별로 다른 값을 주입합니다.
class MinglitColorSet {
  const MinglitColorSet({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color info;
  final Color warning;
  final Color error;

  static const light = MinglitColorSet(
    background: MinglitColors.background,
    surface: MinglitColors.surface,
    primary: MinglitColors.primary,
    secondary: MinglitColors.secondary,
    textPrimary: MinglitColors.textPrimary,
    textSecondary: MinglitColors.textSecondary,
    divider: MinglitColors.divider,
    success: MinglitColors.success,
    info: MinglitColors.info,
    warning: MinglitColors.warning,
    error: MinglitColors.error,
  );

  static const dark = MinglitColorSet(
    background: MinglitColorsDark.background,
    surface: MinglitColorsDark.surface,
    primary: MinglitColorsDark.primary,
    secondary: MinglitColorsDark.secondary,
    textPrimary: MinglitColorsDark.textPrimary,
    textSecondary: MinglitColorsDark.textSecondary,
    divider: MinglitColorsDark.divider,
    success: MinglitColorsDark.success,
    info: MinglitColorsDark.info,
    warning: MinglitColorsDark.warning,
    error: MinglitColorsDark.error,
  );
}

/// Spacing scale constants for consistent layout.
class MinglitSpacing {
  /// 0px zero spacing.
  static const double zero = MdsTokens.spacingZero;

  /// 2px extra-extra-small spacing.
  static const double xxsmall = MdsTokens.spacingXxsmall;

  /// 4px extra-small spacing.
  static const double xsmall = MdsTokens.spacingXsmall;

  /// 6px extra-small-2 spacing.
  static const double xsmall2 = MdsTokens.spacingXsmall2;

  /// 8px small spacing.
  static const double small = MdsTokens.spacingSmall;

  /// 12px small-medium spacing.
  static const double sm = MdsTokens.spacingSm;

  /// 16px medium spacing.
  static const double medium = MdsTokens.spacingMedium;

  /// 24px large spacing.
  static const double large = MdsTokens.spacingLarge;

  /// 32px extra-large spacing.
  static const double xlarge = MdsTokens.spacingXlarge;

  /// 48px extra-extra-large spacing.
  static const double xxlarge = MdsTokens.spacingXxlarge;

  /// 64px extra-extra-extra-large spacing.
  static const double xxxlarge = MdsTokens.spacingXxxlarge;

  // 시맨틱 토큰 (용도별)

  /// 16px screen edge padding (left/right).
  static const double screenEdge = MdsTokens.spacingScreenEdge;

  /// 12px gap between cards.
  static const double cardGap = MdsTokens.spacingCardGap;

  /// 16px card internal vertical padding.
  static const double cardContentV = MdsTokens.spacingCardContentV;

  /// 4px title-to-body spacing.
  static const double titleToBody = MdsTokens.spacingTitleToBody;

  /// 40px section gap.
  static const double sectionGap = MdsTokens.spacingSectionGap;
}

/// Border radius constants for consistent rounding.
class MinglitRadius {
  /// 8px small border radius.
  static const double small = MdsTokens.radiusSmall;

  /// 12px button border radius.
  static const double button = MdsTokens.radiusButton;

  /// 16px card border radius.
  static const double card = MdsTokens.radiusCard;

  /// 28px dialog border radius.
  static const double dialog = MdsTokens.radiusDialog;

  /// 12px input border radius.
  static const double input = MdsTokens.radiusInput;

  /// 4px badge border radius.
  static const double badge = MdsTokens.radiusBadge;

  /// 100px chip border radius (fully rounded).
  static const double chip = MdsTokens.radiusChip;
}

/// Icon size constants for consistent icon rendering.
class MinglitIconSize {
  /// 16px extra-small icon size.
  // TODO(mds-tokens): add iconSizeXsmall to tokens.json and migrate
  static const double xsmall = 16;

  /// 20px small icon size.
  // TODO(mds-tokens): add iconSizeSmall to tokens.json and migrate
  static const double small = 20;

  /// 24px medium icon size.
  // TODO(mds-tokens): add iconSizeMedium to tokens.json and migrate
  static const double medium = 24;

  /// 28px large icon size.
  // TODO(mds-tokens): add iconSizeLarge to tokens.json and migrate
  static const double large = 28;

  /// 32px extra-large icon size.
  // TODO(mds-tokens): add iconSizeXlarge to tokens.json and migrate
  static const double xlarge = 32;

  /// 40px extra-extra-large icon size.
  // TODO(mds-tokens): add iconSizeXxlarge to tokens.json and migrate
  static const double xxlarge = 40;

  /// 48px display icon size — empty state full-page variant.
  // TODO(mds-tokens): add iconSizeDisplay to tokens.json and migrate
  static const double display = 48;
}

/// Partner app brand colors — same purple family, toned down for business feel.
class MinglitPartnerColors {
  /// Primary brand indigo (toned-down purple).
  static const primary = Color(MdsTokens.colorPartnerPrimary);

  /// Lighter variant for gradients.
  static const primaryLight = Color(MdsTokens.colorPartnerPrimaryLight);

  /// Surface tint for cards and containers.
  static const primarySurface = Color(MdsTokens.colorPartnerPrimarySurface);

  /// Border color for highlighted cards.
  static const primaryBorder = Color(MdsTokens.colorPartnerPrimaryBorder);

  /// Container fill for secondary buttons.
  static const primaryContainer = Color(MdsTokens.colorPartnerPrimaryContainer);
}

/// Partner app dark mode colors.
class MinglitPartnerColorsDark {
  // ignore: minglit_no_hardcoded_colors -- partner dark theme definition
  static const primary = Color(MdsTokens.colorPartnerDarkPrimary);
  // ignore: minglit_no_hardcoded_colors -- partner dark theme definition
  static const primaryLight = Color(MdsTokens.colorPartnerDarkPrimaryLight);
}

/// Animation duration constants.
class MinglitAnimation {
  /// 100ms micro animation duration for micro-interactions.
  // TODO(mds-tokens): add animationDurationMicro to tokens.json and migrate
  static const Duration micro = Duration(milliseconds: 100);

  /// 200ms fast animation duration.
  // TODO(mds-tokens): add animationDurationFast to tokens.json and migrate
  static const Duration fast = Duration(milliseconds: 200);

  /// 350ms medium animation duration.
  // TODO(mds-tokens): add animationDurationMedium to tokens.json and migrate
  static const Duration medium = Duration(milliseconds: 350);

  /// 500ms slow animation duration.
  // TODO(mds-tokens): add animationDurationSlow to tokens.json and migrate
  static const Duration slow = Duration(milliseconds: 500);
}

/// Opacity constants for consistent transparency values.
class MinglitOpacity {
  /// 0% opacity — fully transparent overlays.
  // TODO(mds-tokens): add opacity tokens to tokens.json and migrate
  static const double none = 0;

  /// 2% opacity — ultra subtle shadow wash.
  static const double shadowXs = 0.02;

  /// 3% opacity — soft elevated shadow.
  static const double shadowSm = 0.03;

  /// 12% opacity — medium-depth card shadow.
  static const double shadowMd = 0.12;

  /// 4% opacity — shimmer highlight.
  static const double shimmerHighlight = 0.04;

  /// 5% opacity — tint fill, selected card background.
  static const double tintFill = 0.05;

  /// 6% opacity — extra subtle primary tint.
  static const double softTint = 0.06;

  /// 8% opacity — active chip/tag background.
  static const double activeChip = 0.08;

  /// 10% opacity — event phase status indicator background (recruiting/preparing/live).
  static const double highlight = 0.1;

  /// 12% opacity — skeleton base fill.
  static const double skeletonBase = 0.12;

  /// 15% opacity — avatar placeholder background.
  static const double placeholder = 0.15;

  /// 20% opacity — unfilled gauge segments.
  static const double subtle = 0.2;

  /// 26% opacity — low-emphasis overlay.
  static const double lowEmphasis = 0.26;

  /// 30% opacity — muted/empty elements.
  static const double muted = 0.3;

  /// 40% opacity — medium-strength scrim or overlay.
  static const double scrimMedium = 0.4;

  /// 50% opacity — strong overlay or border.
  static const double strong = 0.5;

  /// 54% opacity — medium emphasis content.
  static const double mediumEmphasis = 0.54;

  /// 45% opacity — gradient overlay.
  static const double gradient = 0.45;

  /// 55% opacity — overlay backgrounds (badges, chips on images).
  static const double overlay = 0.55;

  /// 60% opacity — separator/divider text.
  static const double separator = 0.6;

  /// 70% opacity — dark scrim or contrast overlay.
  static const double scrimDark = 0.7;

  /// 80% opacity — light scrim.
  static const double scrimLight = 0.8;

  /// 87% opacity — high-emphasis foreground.
  static const double highEmphasis = 0.87;
}
