import 'package:app_user/src/common/widgets/matching_vote_content.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Phase 3: Matching — MatchingVoteContent + vote count header
// ---------------------------------------------------------------------------

// Fix #664: MATCHING 상태에서 MatchingVoteContent 임베드 + 남은 투표 수 표시
class MatchingContent extends ConsumerWidget {
  const MatchingContent({required this.activeEvent, super.key});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final voteCountAsync = ref.watch(myVoteCountProvider(event.id));
    final maxVoteAsync = ref.watch(maxVoteCountProvider(event.id));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.small),
          _buildVoteStatus(theme, voteCountAsync, maxVoteAsync),
          const SizedBox(height: MinglitSpacing.medium),
          // Fix #664: MatchingVoteContent needs bounded height for internal
          // Expanded + GridView. Use 60% of screen height as content area.
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: MatchingVoteContent(eventId: event.id),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteStatus(
    ThemeData theme,
    AsyncValue<int> voteCountAsync,
    AsyncValue<int> maxVoteAsync,
  ) {
    if (!voteCountAsync.hasValue || !maxVoteAsync.hasValue) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: MinglitCircularProgressIndicator(),
      );
    }

    final voteCount = voteCountAsync.value!;
    final maxVote = maxVoteAsync.value!;
    final remaining = maxVote - voteCount;
    final text = remaining > 0 ? '남은 투표: $remaining / $maxVote' : '투표 완료!';

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: remaining > 0 ? MinglitColors.secondary : MinglitColors.success,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: MinglitColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
