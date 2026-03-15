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
                ref
                    .read(
                      socialInteractionControllerProvider(
                        targetId: targetId,
                        targetType: targetType,
                        interactionType: interactionType,
                      ).notifier,
                    )
                    .toggle();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.small,
            vertical: MinglitSpacing.xxsmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MinglitRadius.small),
            border: isActive
                ? null
                : Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: MinglitCircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  size: 14,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: MinglitSpacing.xxsmall),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: isActive
                      ? Colors.white
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
