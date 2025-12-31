import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A sleek card for selecting verifications in a list.
class VerificationSelectCard extends StatelessWidget {
  const VerificationSelectCard({
    required this.verification,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final Verification verification;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary; // Spark Orange for selection

    return AnimatedContainer(
      duration: MinglitAnimation.fast,
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      decoration: MinglitDecorations.selectableCard(
        context,
        isSelected: isSelected,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          MinglitRadius.card - 2,
        ), // Adjust for border
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align to top for multiline
            children: [
              // Icon Section
              _buildCategoryIcon(
                verification.category,
                isSelected,
                accentColor,
                colorScheme,
              ),
              const SizedBox(width: MinglitSpacing.medium),

              // Text Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.displayName,
                      style: MinglitTextStyles.selectableCardTitle(
                        context,
                        isSelected: isSelected,
                      ),
                    ),
                    // Show internal name if it's different and exists
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
                        padding: const EdgeInsets.only(
                          top: MinglitSpacing.xsmall,
                        ),
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

              const SizedBox(width: MinglitSpacing.small),

              // Selection Indicator (Aligned to top-right)
              Padding(
                padding: const EdgeInsets.only(top: MinglitSpacing.xsmall),
                child: AnimatedSwitcher(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(
    VerificationCategory category,
    bool isSelected,
    Color activeColor,
    ColorScheme colorScheme,
  ) {
    final iconData = switch (category) {
      VerificationCategory.career => Icons.work_outline,
      VerificationCategory.academic => Icons.school_outlined,
      VerificationCategory.asset => Icons.account_balance_wallet_outlined,
      VerificationCategory.marriage => Icons.favorite_border,
      VerificationCategory.vehicle => Icons.directions_car_outlined,
      VerificationCategory.etc => Icons.verified_user_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
        size: MinglitIconSize.small,
      ),
    );
  }
}
