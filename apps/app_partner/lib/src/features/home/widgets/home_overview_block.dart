import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeOverviewBlock extends StatelessWidget {
  const HomeOverviewBlock({
    required this.totalPartyCount,
    required this.pendingApplications,
    required this.onPartiesTap,
    required this.onPendingTap,
    super.key,
  });

  final int totalPartyCount;
  final int pendingApplications;
  final VoidCallback onPartiesTap;
  final VoidCallback onPendingTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: totalPartyCount.toString(),
            label: '등록된 파티',
            onTap: onPartiesTap,
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: _StatChip(
            value: pendingApplications.toString(),
            label: '심사 대기',
            onTap: onPendingTap,
            highlight: pendingApplications > 0,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final String value;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? MinglitColors.error
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.medium,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xxsmall),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
