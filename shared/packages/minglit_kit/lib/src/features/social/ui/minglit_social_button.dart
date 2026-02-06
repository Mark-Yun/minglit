import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';

/// **Minglit Social Button**
///
/// A standardized button for social interactions (Like, Subscribe, Bookmark).
/// Handles optimistic updates and displays counts.
class MinglitSocialButton extends ConsumerWidget {
  const MinglitSocialButton({
    required this.targetId,
    required this.targetType,
    required this.interactionType,
    this.showCount = false,
    this.activeColor,
    this.inactiveColor,
    this.iconSize = MinglitIconSize.medium,
    super.key,
  });

  final String targetId;
  final SocialTargetType targetType;
  final SocialInteractionType interactionType;
  final bool showCount;
  final Color? activeColor;
  final Color? inactiveColor;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(
      socialInteractionControllerProvider(
        targetId: targetId,
        targetType: targetType,
        interactionType: interactionType,
      ),
    );

    return MinglitAsyncValueWidget(
      value: asyncState,
      data: (state) => _buildButton(context, ref, state),
      loading: () => _buildLoading(context),
      error: (e, s) => _buildError(context),
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    InteractionState state,
  ) {
    final theme = Theme.of(context);
    final color = state.isActive
        ? (activeColor ?? _getDefaultActiveColor(theme))
        : (inactiveColor ?? theme.colorScheme.onSurfaceVariant);

    return InkWell(
      onTap: () => ref
          .read(
            socialInteractionControllerProvider(
              targetId: targetId,
              targetType: targetType,
              interactionType: interactionType,
            ).notifier,
          )
          .toggle(),
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xxsmall),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(state.isActive),
              color: color,
              size: iconSize,
            ),
            if (showCount && state.count > 0) ...[
              const SizedBox(width: MinglitSpacing.xxsmall),
              Text(
                '${state.count}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: state.isActive ? FontWeight.bold : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: const MinglitCircularProgressIndicator(strokeWidth: 1.5),
    );
  }

  Widget _buildError(BuildContext context) {
    return Icon(
      Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
      size: iconSize,
    );
  }

  IconData _getIcon(bool isActive) {
    return switch (interactionType) {
      SocialInteractionType.like =>
        isActive ? Icons.favorite : Icons.favorite_border,
      SocialInteractionType.subscribe =>
        isActive ? Icons.notifications_active : Icons.notifications_none,
      SocialInteractionType.bookmark =>
        isActive ? Icons.bookmark : Icons.bookmark_border,
      SocialInteractionType.block => Icons.block,
    };
  }

  Color _getDefaultActiveColor(ThemeData theme) {
    return switch (interactionType) {
      SocialInteractionType.like => theme.colorScheme.error,
      SocialInteractionType.subscribe => theme.colorScheme.secondary,
      SocialInteractionType.bookmark => theme.colorScheme.primary,
      _ => theme.colorScheme.primary,
    };
  }
}
