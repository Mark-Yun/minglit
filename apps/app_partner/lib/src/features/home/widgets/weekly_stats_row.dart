import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Weekly performance stats row (revenue, applications, checkin rate).
/// Shows skeleton when loading, hides on error (non-critical section).
class WeeklyStatsRow extends StatelessWidget {
  const WeeklyStatsRow({
    required this.totalRevenue,
    required this.totalApplications,
    required this.checkinRate,
    this.revenueChange,
    this.applicationChange,
    this.checkinRateChange,
    super.key,
  });

  final int totalRevenue;
  final int totalApplications;
  final double checkinRate;
  final double? revenueChange;
  final double? applicationChange;
  final double? checkinRateChange;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(MinglitRadius.input),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '₩${_formatCompact(totalRevenue)}',
            label: '매출',
            change: revenueChange,
            isFirst: true,
            theme: theme,
          ),
          _StatItem(
            value: fmt.format(totalApplications),
            label: '신청',
            change: applicationChange,
            theme: theme,
          ),
          _StatItem(
            value: '${checkinRate.round()}%',
            label: '체크인율',
            change: checkinRateChange,
            isLast: true,
            theme: theme,
          ),
        ],
      ),
    );
  }

  static String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.theme,
    this.change,
    this.isFirst = false,
    this.isLast = false,
  });

  final String value;
  final String label;
  final double? change;
  final bool isFirst;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: MinglitSpacing.medium,
          horizontal: MinglitSpacing.small,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(
            left: isFirst
                ? const Radius.circular(MinglitRadius.input)
                : Radius.zero,
            right: isLast
                ? const Radius.circular(MinglitRadius.input)
                : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MinglitSpacing.xxsmall),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: MinglitSpacing.xxsmall),
              Text(
                change! >= 0
                    ? '+${change!.round()}% ↑'
                    : '${change!.round()}% ↓',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: change! >= 0
                      ? MinglitColors.success
                      : MinglitColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
