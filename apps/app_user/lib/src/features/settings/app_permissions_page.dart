import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #139: Placeholder app permissions page for future permission management.
class AppPermissionsPage extends StatelessWidget {
  /// Creates an [AppPermissionsPage].
  const AppPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('권한 설정')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
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
              '앱 권한 관리 기능이 곧 추가될 예정입니다',
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
