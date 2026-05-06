import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Empty state when no events exist.
class EventActionCardEmpty extends StatelessWidget {
  const EventActionCardEmpty({
    required this.hasParties,
    required this.onCreateEvent,
    required this.onCreateParty,
    super.key,
  });

  final bool hasParties;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateParty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MinglitRadius.button),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            hasParties ? Icons.event_outlined : Icons.celebration_outlined,
            size: MinglitIconSize.xlarge * 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: MinglitSpacing.sm),
          Text(
            hasParties ? '이벤트를 만들어 신청을 받아보세요' : '첫 파티를 만들어보세요',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasParties ? onCreateEvent : onCreateParty,
              icon: const Icon(Icons.add, size: MinglitIconSize.small),
              label: Text(hasParties ? '이벤트 만들기' : '파티 만들기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MinglitRadius.input),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
