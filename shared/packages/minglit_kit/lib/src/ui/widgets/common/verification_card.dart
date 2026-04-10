import 'package:flutter/material.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A pure display component for Verification info.
/// Can be composed into SelectCard, ManageCard, etc.
class VerificationCard extends StatelessWidget {
  /// Creates a card that displays [Verification] details.
  const VerificationCard({
    required this.verification,
    this.onTap,
    this.trailing,
    this.backgroundColor,
    this.borderColor,
    this.contentPadding,
    super.key,
  });

  /// Verification data to display.
  final Verification verification;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  /// Optional trailing widget shown at the end.
  final Widget? trailing;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional border color override.
  final Color? borderColor;

  /// Optional padding for the card content.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build Category Icon
    final iconData = switch (verification.category) {
      VerificationCategory.career => Icons.work_outline,
      VerificationCategory.academic => Icons.school_outlined,
      VerificationCategory.asset => Icons.account_balance_wallet_outlined,
      VerificationCategory.marriage => Icons.favorite_border,
      VerificationCategory.vehicle => Icons.directions_car_outlined,
      VerificationCategory.etc => Icons.verified_user_outlined,
    };

    final iconWidget = Container(
      padding: const EdgeInsets.all(
        MinglitSpacing.small + MinglitSpacing.xxsmall,
      ), // 10
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: MinglitOpacity.strong,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: colorScheme.onSurfaceVariant,
        size: MinglitIconSize.small,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color:
              borderColor ??
              colorScheme.outlineVariant.withValues(
                alpha: MinglitOpacity.strong,
              ),
        ),
        boxShadow: [
          if (backgroundColor == null || backgroundColor == colorScheme.surface)
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: MinglitOpacity.shadowSm,
              ),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding:
              contentPadding ?? const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              iconWidget,
              const SizedBox(width: MinglitSpacing.medium),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.displayName,
                      style: MinglitTextStyles.selectableCardTitle(
                        context,
                        isSelected: false,
                      ),
                    ),
                    if (verification.internalName.isNotEmpty &&
                        verification.internalName != verification.displayName)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: MinglitSpacing.xxsmall,
                        ),
                        child: Text(
                          '[${verification.internalName}]',
                          style: MinglitTextStyles.selectableCardSubtitle(
                            context,
                          ),
                        ),
                      ),
                    if (verification.description != null &&
                        verification.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Text(
                          verification.description!,
                          style: MinglitTextStyles.selectableCardDescription(
                            context,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Trailing Widget (Slot)
              if (trailing != null) ...[
                const SizedBox(width: MinglitSpacing.small),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
