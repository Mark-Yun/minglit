import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Variant type for internal use.
enum _BottomCTAVariant { single, dual, price }

/// **Minglit Bottom CTA**
///
/// 화면 하단에 고정되는 핵심 액션 버튼 위젯.
/// `Scaffold.bottomNavigationBar`에 배치하여 사용합니다.
///
/// 세 가지 변형을 지원합니다:
/// - **기본**: 단일 전체 너비 버튼
/// - **dual**: 좌(보조) + 우(주요) 버튼
/// - **withPrice**: 좌측 가격 텍스트 + 우측 버튼
///
/// SafeArea를 자동 처리하며, 키보드가 올라오면 자동으로 숨깁니다.
class MinglitBottomCTA extends StatelessWidget {
  /// 단일 버튼 CTA.
  const MinglitBottomCTA({
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    super.key,
  }) : secondaryLabel = null,
       onSecondaryPressed = null,
       priceText = null,
       priceSubText = null,
       _variant = _BottomCTAVariant.single;

  /// 좌우 두 버튼 CTA.
  ///
  /// 좌측은 OutlinedButton(보조), 우측은 ElevatedButton(주요).
  const MinglitBottomCTA.dual({
    required this.label,
    required this.onPressed,
    required String this.secondaryLabel,
    required VoidCallback this.onSecondaryPressed,
    this.enabled = true,
    super.key,
  }) : icon = null,
       priceText = null,
       priceSubText = null,
       _variant = _BottomCTAVariant.dual;

  /// 가격 표시 + 버튼 CTA.
  ///
  /// 좌측에 가격 정보, 우측에 액션 버튼을 표시합니다.
  /// 예: "최저가 20,000원~ | 참가 신청하기"
  const MinglitBottomCTA.withPrice({
    required this.label,
    required this.onPressed,
    required String this.priceText,
    this.priceSubText,
    this.icon,
    this.enabled = true,
    super.key,
  }) : secondaryLabel = null,
       onSecondaryPressed = null,
       _variant = _BottomCTAVariant.price;

  /// 주요 버튼 텍스트.
  final String label;

  /// 주요 버튼 콜백.
  final VoidCallback? onPressed;

  /// 주요 버튼 아이콘 (선택).
  final IconData? icon;

  /// 버튼 활성화 여부.
  final bool enabled;

  /// `MinglitBottomCTA.dual` 변형의 보조 버튼 텍스트.
  final String? secondaryLabel;

  /// `MinglitBottomCTA.dual` 변형의 보조 버튼 콜백.
  final VoidCallback? onSecondaryPressed;

  /// `MinglitBottomCTA.withPrice` 변형의 가격 텍스트 (예: "20,000원~").
  final String? priceText;

  /// `MinglitBottomCTA.withPrice` 변형의 가격 부가 텍스트 (예: "최저가").
  final String? priceSubText;

  final _BottomCTAVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.screenEdge,
            vertical: MinglitSpacing.sm,
          ),
          child: switch (_variant) {
            _BottomCTAVariant.single => _buildSingle(theme),
            _BottomCTAVariant.dual => _buildDual(theme),
            _BottomCTAVariant.price => _buildPrice(theme),
          },
        ),
      ),
    );
  }

  Widget _buildSingle(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: _primaryButton(theme),
    );
  }

  Widget _buildDual(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: enabled ? onSecondaryPressed : null,
            child: Text(secondaryLabel!),
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: _primaryButton(theme),
        ),
      ],
    );
  }

  Widget _buildPrice(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (priceSubText != null)
                Text(
                  priceSubText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                priceText!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: MinglitSpacing.sm),
        _primaryButton(theme),
      ],
    );
  }

  Widget _primaryButton(ThemeData theme) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: MinglitIconSize.small),
        label: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      child: Text(label),
    );
  }
}
