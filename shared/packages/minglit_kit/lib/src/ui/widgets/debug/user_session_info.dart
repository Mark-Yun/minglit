import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
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
        title: Text(
          'Session: ${user.email ?? user.id}',
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: MinglitColors.textSecondary,
          ),
        ),
        subtitle: Text(
          'Tap to view full session JSON',
          style: theme.textTheme.bodySmall!.copyWith(fontSize: 11),
        ),
        leading: const Icon(
          Icons.account_circle,
          color: MinglitColors.textSecondary,
        ),
        childrenPadding: const EdgeInsets.all(MinglitSpacing.medium),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User ID',
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          SelectableText(user.id, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(
            'Full Metadata (JSON)',
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MinglitSpacing.small),
            decoration: BoxDecoration(
              color: MinglitColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              prettyMetadata,
              style: theme.textTheme.bodySmall!.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
                color: MinglitColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
