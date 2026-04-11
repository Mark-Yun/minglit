import 'package:flutter/material.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/verification_card.dart';

/// A wrapper around [VerificationCard] that adds selection logic (checkbox).
class VerificationSelectCard extends StatelessWidget {
  /// Creates a selectable wrapper around [VerificationCard].
  const VerificationSelectCard({
    required this.verification,
    required this.isSelected,
    this.onTap,
    this.isReadOnly = false,
    super.key,
  });

  /// Verification data to display.
  final Verification verification;

  /// Whether the card is currently selected.
  final bool isSelected;

  /// Optional tap handler for selection.
  final VoidCallback? onTap;

  /// Whether selection is disabled.
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary;

    // Calculate styles based on selection state
    final backgroundColor = isSelected
        ? colorScheme.secondaryContainer.withValues(
            alpha: MinglitOpacity.highlight,
          )
        : null;
    final borderColor = isSelected ? accentColor : null;

    return VerificationCard(
      verification: verification,
      onTap: isReadOnly ? null : onTap,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      trailing: !isReadOnly
          ? AnimatedSwitcher(
              duration: MinglitAnimation.fast,
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: accentColor,
                      size: MinglitIconSize.large,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      key: const ValueKey('unchecked'),
                      color: colorScheme.outlineVariant,
                      size: MinglitIconSize.large,
                    ),
            )
          : null,
    );
  }
}
