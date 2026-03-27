import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Placeholder page for the Check-in tab.
/// Will be replaced with full QR scanner + event auto-selection in #523.
class CheckinPlaceholderPage extends StatelessWidget {
  const CheckinPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '체크인'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: MinglitIconSize.xlarge * 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '오늘 예정된 이벤트가 없습니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '이벤트 당일에 체크인을 시작할 수 있어요',
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
