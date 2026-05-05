import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeApprovalPendingCard extends StatelessWidget {
  const HomeApprovalPendingCard({
    required this.pendingCount,
    required this.onReview,
    super.key,
  });

  final int pendingCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onReview,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        leading: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.small,
            vertical: MinglitSpacing.xsmall,
          ),
          decoration: BoxDecoration(
            color: MinglitColors.error.withValues(
              alpha: MinglitOpacity.tintFill,
            ),
            borderRadius: BorderRadius.circular(MinglitRadius.button),
          ),
          child: Text(
            pendingCount.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: MinglitColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          '심사 대기',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text('신청서를 검토해주세요'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
