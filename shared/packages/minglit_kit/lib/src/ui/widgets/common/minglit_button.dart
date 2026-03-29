import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Button variant for [MinglitButton].
enum MinglitButtonVariant {
  /// Filled button with primary background. Use for primary CTA actions.
  primary,

  /// Outlined button with primary border. Use for secondary actions.
  secondary,

  /// Text-only button. Use for tertiary or inline actions.
  text,
}

/// Button size for [MinglitButton].
enum MinglitButtonSize {
  /// Small button (height 36, fontSize 14).
  small,

  /// Medium button (height 48, fontSize 15).
  medium,

  /// Large button (height 56, fontSize 16). Default for full-width CTAs.
  large,
}

/// **Minglit Button**
///
/// A unified button widget that enforces Minglit design tokens
/// (radius, spacing, typography) across all button variants.
///
/// Wraps Material buttons ([ElevatedButton], [OutlinedButton], [TextButton])
/// with consistent sizing and styling.
///
/// {@tool snippet}
/// ```dart
/// // Primary CTA
/// MinglitButton(
///   label: '참가하기',
///   onPressed: () => submit(),
/// )
///
/// // Secondary action
/// MinglitButton.secondary(
///   label: '취소',
///   onPressed: () => cancel(),
/// )
///
/// // Text button with icon
/// MinglitButton.text(
///   label: '더보기',
///   icon: Icons.arrow_forward,
///   onPressed: () => viewMore(),
/// )
/// ```
/// {@end-tool}
class MinglitButton extends StatelessWidget {
  /// Creates a primary (filled) button.
  const MinglitButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = MinglitButtonSize.large,
    this.expand = true,
    super.key,
  }) : variant = MinglitButtonVariant.primary;

  /// Creates a secondary (outlined) button.
  const MinglitButton.secondary({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = MinglitButtonSize.large,
    this.expand = true,
    super.key,
  }) : variant = MinglitButtonVariant.secondary;

  /// Creates a text button.
  const MinglitButton.text({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = MinglitButtonSize.medium,
    this.expand = false,
    super.key,
  }) : variant = MinglitButtonVariant.text;

  /// Button label text.
  final String label;

  /// Called when the button is pressed. Null disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// When `true`, shows a loading indicator and disables the button.
  final bool isLoading;

  /// Button visual variant.
  final MinglitButtonVariant variant;

  /// Button size controlling height and text size.
  final MinglitButtonSize size;

  /// When `true`, the button expands to fill available width.
  /// Defaults to `true` for primary/secondary, `false` for text.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget button;
    switch (variant) {
      case MinglitButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: _primaryStyle(context),
          child: child,
        );
      case MinglitButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _secondaryStyle(context),
          child: child,
        );
      case MinglitButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: _textStyle(context),
          child: child,
        );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildChild(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      final color = variant == MinglitButtonVariant.primary
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.primary;
      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize),
          const SizedBox(width: MinglitSpacing.small),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  double get _height {
    switch (size) {
      case MinglitButtonSize.small:
        return 36;
      case MinglitButtonSize.medium:
        return 48;
      case MinglitButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (size) {
      case MinglitButtonSize.small:
        return 14;
      case MinglitButtonSize.medium:
        return 15;
      case MinglitButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case MinglitButtonSize.small:
        return 16;
      case MinglitButtonSize.medium:
        return 18;
      case MinglitButtonSize.large:
        return 20;
    }
  }

  ButtonStyle _primaryStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: MinglitColors.primary,
      // ignore: minglit_no_hardcoded_colors -- button theme definition
      foregroundColor: Colors.white,
      minimumSize: Size(0, _height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      elevation: 0,
      textStyle: TextStyle(
        // ignore: minglit_no_hardcoded_text_style -- button theme definition
        fontSize: _fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  ButtonStyle _secondaryStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: MinglitColors.primary,
      minimumSize: Size(0, _height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      side: const BorderSide(color: MinglitColors.primary),
      textStyle: TextStyle(
        // ignore: minglit_no_hardcoded_text_style -- button theme definition
        fontSize: _fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  ButtonStyle _textStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: MinglitColors.primary,
      minimumSize: Size(0, _height),
      textStyle: TextStyle(
        // ignore: minglit_no_hardcoded_text_style -- button theme definition
        fontSize: _fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
