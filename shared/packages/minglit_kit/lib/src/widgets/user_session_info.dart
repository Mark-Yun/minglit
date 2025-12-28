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
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blueGrey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Session',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText('ID: ${user.id}'),
          SelectableText('Email: ${user.email ?? 'N/A'}'),
          if (user.userMetadata != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Metadata:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SelectableText(user.userMetadata.toString()),
          ],
        ],
      ),
    );
  }
}
