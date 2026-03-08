import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Horizontal scrolling party summary cards.
class ActivePartySummaryScroll extends StatelessWidget {
  const ActivePartySummaryScroll({
    required this.parties,
    required this.onPartyTap,
    super.key,
  });

  final List<Party> parties;
  final void Function(Party party) onPartyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
          child: Row(
            children: [
              Icon(
                Icons.celebration,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '파티별 요약',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (parties.isEmpty)
          SizedBox(
            height: 100,
            child: Center(
              child: Text(
                '운영 중인 파티가 없습니다',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: parties.length,
              separatorBuilder: (_, _) => const SizedBox(
                width: MinglitSpacing.small,
              ),
              itemBuilder: (context, index) {
                final party = parties[index];
                return _PartyCard(
                  party: party,
                  onTap: () => onPartyTap(party),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.party,
    required this.onTap,
  });

  final Party party;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  party.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '최대 ${party.maxParticipants}명',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
