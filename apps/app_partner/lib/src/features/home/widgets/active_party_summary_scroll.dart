import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Horizontal scrolling party summary cards.
class ActivePartySummaryScroll extends StatelessWidget {
  const ActivePartySummaryScroll({
    required this.parties,
    required this.onPartyTap,
    this.onViewAllTap,
    super.key,
  });

  final List<Party> parties;
  final void Function(Party party) onPartyTap;
  // Fix #185: 파티 전체 보기 버튼 콜백
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix #422: 헤더에 가로 패딩 적용 (수평 스크롤은 화면 전체 사용)
        Padding(
          padding: const EdgeInsets.only(
            left: MinglitSpacing.medium,
            right: MinglitSpacing.medium,
            bottom: MinglitSpacing.small,
          ),
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
              // Fix #185: 파티 전체 보기 버튼
              if (onViewAllTap != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '자세히',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (parties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  '운영 중인 파티가 없습니다',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Fix #422: 좌우 패딩으로 카드 잘림 방지
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
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
