import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #139: Placeholder privacy page for future privacy settings.
class PrivacyPage extends StatelessWidget {
  /// Creates a [PrivacyPage].
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '준비 중입니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '개인정보 관련 설정이 곧 추가될 예정입니다',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
