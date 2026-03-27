import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
import 'package:minglit_kit/src/theme/minglit_text_theme_extension.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A widget that displays the current user's session information.
/// Useful for debugging and development screens.
class UserSessionInfo extends ConsumerWidget {
  /// Creates a [UserSessionInfo].
  const UserSessionInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MinglitSpacing.sm),
        color: MinglitColors.error.withValues(alpha: 0.1),
        child: Text(
          'No Active Session',
          style: theme.textTheme.bodySmall!.copyWith(
            color: MinglitColors.error,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    const encoder = JsonEncoder.withIndent('  ');
    final prettyMetadata = user.userMetadata != null
        ? encoder.convert(user.userMetadata)
        : '{}';

    return Container(
      width: double.infinity,
      color: MinglitColors.surface,
      child: ExpansionTile(
        dense: true,
        // Fix #474: fontSize 13 → ext.chipLabel, fontSize 11 → labelSmall
        title: Text(
          'Session: ${user.email ?? user.id}',
          style: Theme.of(context)
              .extension<MinglitTextThemeExtension>()!
              .chipLabel
              .copyWith(
                fontWeight: FontWeight.bold,
                color: MinglitColors.textSecondary,
              ),
        ),
        subtitle: Text(
          'Tap to view full session JSON',
          style: theme.textTheme.labelSmall,
        ),
        leading: const Icon(
          Icons.account_circle,
          color: MinglitColors.textSecondary,
        ),
        childrenPadding: const EdgeInsets.all(MinglitSpacing.medium),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix #474: fontSize 11 → labelSmall
          Text(
            'User ID',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SelectableText(user.id, style: theme.textTheme.bodySmall),
          const SizedBox(height: MinglitSpacing.sm),
          // Fix #474: fontSize 11 → labelSmall
          Text(
            'Full Metadata (JSON)',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MinglitSpacing.small),
            decoration: BoxDecoration(
              color: MinglitColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            // Fix #474: fontSize 11 → labelSmall
            child: SelectableText(
              prettyMetadata,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: MinglitColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(
                ref.read(authControllerProvider.notifier).signOut(),
              ),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
