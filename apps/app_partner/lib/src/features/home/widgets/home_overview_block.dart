import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// spec: apps/mds/docs/public/specs/partner_home_page.html#overview-block
// 3-up stat row: 등록된 파티 / 모집 중인 이벤트 / 참가예정 고객
class HomeOverviewBlock extends StatelessWidget {
  const HomeOverviewBlock({
    required this.totalPartyCount,
    required this.recruitingCount,
    required this.totalAttendees,
    required this.onPartiesTap,
    required this.onEventsTap,
    required this.onAttendeesTap,
    super.key,
  });

  final int totalPartyCount;
  final int recruitingCount;
  final int totalAttendees;
  final VoidCallback onPartiesTap;
  final VoidCallback onEventsTap;
  final VoidCallback onAttendeesTap;

  @override
  Widget build(BuildContext context) {
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
            value: recruitingCount.toString(),
            label: '모집 중인 이벤트',
            onTap: onEventsTap,
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: _StatChip(
            value: totalAttendees.toString(),
            label: '참가예정 고객',
            onTap: onAttendeesTap,
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
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.small,
            vertical: MinglitSpacing.medium,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xxsmall),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
