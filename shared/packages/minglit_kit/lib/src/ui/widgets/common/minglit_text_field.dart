import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Text Field**
///
/// A themed text input widget for the Minglit design system.
/// Wraps Material [TextField] with Minglit design tokens for consistent
/// border radius, spacing, and color across all input fields.
///
/// Supports label, hint, error/helper text, prefix/suffix icons,
/// and automatically adapts to light/dark mode via semantic colors.
///
/// {@tool snippet}
/// ```dart
/// MinglitTextField(
///   label: '이메일',
///   hintText: 'example@minglit.com',
///   keyboardType: TextInputType.emailAddress,
/// )
/// ```
/// {@end-tool}
class MinglitTextField extends StatelessWidget {
  /// Creates a Minglit-themed text field with [label].
  const MinglitTextField({
    required this.label,
    this.controller,
    this.errorText,
    this.helperText,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(maxLines > 0, 'maxLines must be greater than 0'),
       assert(
         !obscureText || maxLines == 1,
         'obscureText=true requires maxLines=1',
       );

  /// Label text displayed above the input.
  final String label;

  /// Optional controller for the text field.
  final TextEditingController? controller;

  /// Error message displayed below the input in error color.
  final String? errorText;

  /// Helper text displayed below the input.
  final String? helperText;

  /// Hint text displayed inside the input when empty.
  final String? hintText;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Maximum number of lines.
  final int maxLines;

  /// Keyboard type for the input.
  final TextInputType? keyboardType;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the input.
  final ValueChanged<String>? onSubmitted;

  /// Icon displayed at the start of the input.
  final Widget? prefixIcon;

  /// Icon displayed at the end of the input.
  final Widget? suffixIcon;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Whether to autofocus on build.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      textField: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          focusNode: focusNode,
          autofocus: autofocus,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(
                  alpha: MinglitOpacity.muted,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
              vertical: MinglitSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}
