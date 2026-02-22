import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';

class MinglitSocialButton extends ConsumerWidget {
  const MinglitSocialButton({
    required this.targetId,
    required this.targetType,
    required this.interactionType,
    this.activeColor,
    this.inactiveColor,
    this.iconSize = MinglitIconSize.medium,
    super.key,
  });

  final String targetId;
  final SocialTargetType targetType;
  final SocialInteractionType interactionType;
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

    return MinglitAsyncValueWidget<bool>(
      value: asyncState,
      data: (isActive) => _buildButton(context, ref, isActive: isActive),
      loading: () => _buildLoading(context),
      error: (e, s) => _buildInactive(context),
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref, {
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final color = isActive
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
        child: Icon(
          _getIcon(isActive),
          color: color,
          size: iconSize,
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

  Widget _buildInactive(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.xxsmall),
      child: Icon(
        _getIcon(false),
        color: inactiveColor ?? theme.colorScheme.onSurfaceVariant,
        size: iconSize,
      ),
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
