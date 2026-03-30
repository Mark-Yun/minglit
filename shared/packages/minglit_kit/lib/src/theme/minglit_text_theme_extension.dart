import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Fix #474: M3 15개 슬롯에 매핑되지 않는 커스텀 텍스트 스타일을 ThemeExtension으로 관리.
///
/// 사용법:
/// ```dart
/// final ext = Theme.of(context).extension<MinglitTextThemeExtension>()!;
/// Text('chip', style: ext.chipLabel);
/// ```
@immutable
class MinglitTextThemeExtension
    extends ThemeExtension<MinglitTextThemeExtension> {
  /// Creates a [MinglitTextThemeExtension].
  const MinglitTextThemeExtension({
    required this.chipLabel,
    required this.appBarTitle,
    required this.captionTiny,
  });

  /// 13px w500 — 이벤트 카드 오버레이, 소셜 버튼, 칩 미디엄
  final TextStyle chipLabel;

  /// 18px w600 — AppBar 타이틀
  final TextStyle appBarTitle;

  /// 10px w500 — 온보딩 플로우 스텝 부제
  final TextStyle captionTiny;

  @override
  MinglitTextThemeExtension copyWith({
    TextStyle? chipLabel,
    TextStyle? appBarTitle,
    TextStyle? captionTiny,
  }) {
    return MinglitTextThemeExtension(
      chipLabel: chipLabel ?? this.chipLabel,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      captionTiny: captionTiny ?? this.captionTiny,
    );
  }

  @override
  MinglitTextThemeExtension lerp(
    covariant MinglitTextThemeExtension? other,
    double t,
  ) {
    if (other is! MinglitTextThemeExtension) return this;
    return MinglitTextThemeExtension(
      chipLabel: TextStyle.lerp(chipLabel, other.chipLabel, t)!,
      appBarTitle: TextStyle.lerp(appBarTitle, other.appBarTitle, t)!,
      captionTiny: TextStyle.lerp(captionTiny, other.captionTiny, t)!,
    );
  }

  /// Light theme text styles.
  // ignore: minglit_no_hardcoded_text_style -- theme extension definition
  static const light = MinglitTextThemeExtension(
    chipLabel: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: MinglitColors.textPrimary,
    ),
    appBarTitle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: MinglitColors.textPrimary,
      fontFamily: 'NotoSansKR',
    ),
    captionTiny: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: MinglitColors.textPrimary,
    ),
  );

  /// Dark theme text styles.
  // ignore: minglit_no_hardcoded_text_style -- theme extension definition
  static const dark = MinglitTextThemeExtension(
    chipLabel: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: MinglitColorsDark.textPrimary,
    ),
    appBarTitle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: MinglitColorsDark.textPrimary,
      fontFamily: 'NotoSansKR',
    ),
    captionTiny: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: MinglitColorsDark.textPrimary,
    ),
  );
}
