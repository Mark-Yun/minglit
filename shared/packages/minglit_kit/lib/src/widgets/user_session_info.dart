import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A widget that displays the current user's session information.
/// Useful for debugging and development screens.
class UserSessionInfo extends ConsumerWidget {
  /// Creates a [UserSessionInfo].
  const UserSessionInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.red[50],
        child: const Text(
          'No Active Session',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
      color: Colors.blueGrey[50],
      child: ExpansionTile(
        dense: true,
        title: Text(
          'Session: ${user.email ?? user.id}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.blueGrey,
          ),
        ),
        subtitle: const Text(
          'Tap to view full session JSON',
          style: TextStyle(fontSize: 11),
        ),
        leading: const Icon(Icons.account_circle, color: Colors.blueGrey),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User ID',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          SelectableText(user.id, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          const Text(
            'Full Metadata (JSON)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              prettyMetadata,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.blueGrey,
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
