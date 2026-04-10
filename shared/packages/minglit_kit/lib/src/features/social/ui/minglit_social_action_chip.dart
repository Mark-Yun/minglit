import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';

/// A chip-style button for social interactions (like/dislike).
///
/// Renders as outlined chip when inactive, filled chip when active.
/// Handles auth guard via [onUnauthenticatedTap].
class MinglitSocialActionChip extends ConsumerWidget {
  /// Creates a [MinglitSocialActionChip].
  const MinglitSocialActionChip({
    required this.targetId,
    required this.targetType,
    required this.interactionType,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor,
    this.onUnauthenticatedTap,
    super.key,
  });

  /// The ID of the target entity.
  final String targetId;

  /// The type of the target.
  final SocialTargetType targetType;

  /// The type of interaction.
  final SocialInteractionType interactionType;

  /// Text label displayed on the chip.
  final String label;

  /// Icon shown when the interaction is active.
  final IconData activeIcon;

  /// Icon shown when the interaction is inactive.
  final IconData inactiveIcon;

  /// Background color when active. Defaults to theme error color.
  final Color? activeColor;

  /// Called when an unauthenticated user taps the chip.
  final VoidCallback? onUnauthenticatedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(
      socialInteractionControllerProvider(
        targetId: targetId,
        targetType: targetType,
        interactionType: interactionType,
      ),
    );

    return asyncState.when(
      data: (isActive) => _buildChip(context, ref, isActive: isActive),
      loading: () => _buildChip(context, ref, isLoading: true),
      error: (_, _) => _buildChip(context, ref),
    );
  }

  Widget _buildChip(
    BuildContext context,
    WidgetRef ref, {
    bool isActive = false,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.colorScheme.error;

    return Material(
      color: isActive ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: InkWell(
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        onTap: isLoading
            ? null
            : () {
                if (onUnauthenticatedTap != null) {
                  onUnauthenticatedTap!();
                  return;
                }
                unawaited(
                  ref
                      .read(
                        socialInteractionControllerProvider(
                          targetId: targetId,
                          targetType: targetType,
                          interactionType: interactionType,
                        ).notifier,
                      )
                      .toggle(),
                );
              },
        // Fix #136: Increase padding, font size, icon size and add separator
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.sm,
            vertical: MinglitSpacing.xsmall2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MinglitRadius.small),
            // Fix #174: 항상 border 유지 — active 시 alpha 0으로 변경하여 크기 변동 방지
            border: Border.all(
              color: theme.colorScheme.outline.withValues(
                alpha: isActive ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: MinglitCircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  size: 16,
                  color: isActive
                      ? MinglitColors.background
                      : theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: MinglitSpacing.xsmall),
              Container(
                width: 1,
                height: 14,
                color: isActive
                    ? MinglitColors.background.withValues(
                        alpha: MinglitOpacity.scrimMedium,
                      )
                    : theme.colorScheme.outlineVariant,
              ),
              const SizedBox(width: MinglitSpacing.xsmall),
              // Fix #474: fontSize 14 → labelLarge
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isActive
                      ? MinglitColors.background
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
