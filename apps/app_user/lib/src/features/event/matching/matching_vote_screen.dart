import 'dart:async';

import 'package:app_user/src/features/event/matching/matching_vote_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Full-screen matching vote page with Scaffold + AppBar.
class MatchingVoteScreen extends ConsumerWidget {
  const MatchingVoteScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '매칭 투표'),
      body: MatchingVoteContent(eventId: eventId),
    );
  }
}

/// Scaffold-free matching vote UI — embeddable in bottom sheets or other hosts.
class MatchingVoteContent extends ConsumerWidget {
  const MatchingVoteContent({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final candidatesAsync = ref.watch(matchCandidatesProvider(eventId));
    final matchesAsync = ref.watch(myMatchesProvider(eventId));
    // Fix #306: 잔여 투표 수 + 투표 완료 후보 추적
    final voteCountAsync = ref.watch(myVoteCountProvider(eventId));
    final maxVoteAsync = ref.watch(maxVoteCountProvider(eventId));
    final votedIdsAsync = ref.watch(myVotedCandidateIdsProvider(eventId));

    // Listen to vote action state
    ref.listen(matchingVoteControllerProvider, (_, state) {
      if (state.hasError) {
        handleMinglitError(
          context,
          state.error!,
          state.stackTrace,
        );
      } else if (!state.isLoading && state.hasValue) {
        // Void async value technically has null value,
        // but let's check !hasError
        context.showMinglitSuccess('투표가 완료되었습니다.');
      }
    });

    return Column(
      children: [
        // 1. Matches (Success)
        MinglitAsyncValueWidget(
          value: matchesAsync,
          data: (matches) {
            if (matches.isEmpty) return const SizedBox.shrink();
            return ColoredBox(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.2,
              ),
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: theme.colorScheme.error,
                          size: MinglitIconSize.small,
                        ),
                        const SizedBox(width: MinglitSpacing.small),
                        Text(
                          '매칭 성공! (${matches.length}명)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: matches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: MinglitSpacing.medium),
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return _buildMatchCard(context, match);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Fix #306: 잔여 투표 수 표시
        if (voteCountAsync.hasValue && maxVoteAsync.hasValue)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
              vertical: MinglitSpacing.small,
            ),
            child: Builder(
              builder: (context) {
                final used = voteCountAsync.value!;
                final max = maxVoteAsync.value!;
                final remaining = max - used;
                final allUsed = remaining <= 0;
                return Row(
                  children: [
                    Icon(
                      allUsed ? Icons.check_circle : Icons.how_to_vote,
                      size: MinglitIconSize.small,
                      color: allUsed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: MinglitSpacing.small),
                    Text(
                      allUsed ? '투표 완료!' : '남은 투표: $remaining/$max',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: allUsed
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // 2. Candidates
        Expanded(
          child: MinglitAsyncValueWidget(
            value: candidatesAsync,
            data: (candidates) {
              if (candidates.isEmpty) {
                return const Center(child: Text('투표 가능한 상대가 없습니다.'));
              }
              final votedIds = votedIdsAsync.hasValue
                  ? votedIdsAsync.value!
                  : <String>{};
              final allVotesUsed =
                  voteCountAsync.hasValue &&
                  maxVoteAsync.hasValue &&
                  voteCountAsync.value! >= maxVoteAsync.value!;
              return GridView.builder(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: MinglitSpacing.medium,
                  crossAxisSpacing: MinglitSpacing.medium,
                ),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  final isVoted = votedIds.contains(candidate.id);
                  return _buildCandidateCard(
                    context,
                    ref,
                    candidate,
                    isVoted: isVoted,
                    isDisabled: isVoted || allVotesUsed,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchPair match) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(MinglitSpacing.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            match.partnerName ?? '알 수 없음',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MinglitSpacing.xxsmall),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: MinglitSpacing.xsmall),
              Expanded(
                child: Text(
                  match.partnerContact ?? '연락처 없음',
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fix #306: isVoted/isDisabled 파라미터 추가
  Widget _buildCandidateCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile candidate, {
    bool isVoted = false,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background (Profile Image Placeholder)
          ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.person,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Fix #306: 투표 완료 체크 오버레이
          if (isVoted)
            Positioned.fill(
              child: ColoredBox(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          // Info Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(MinglitSpacing.small),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    MinglitColors.textPrimary.withValues(alpha: 0.87),
                    MinglitColors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MinglitColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Fix #306: 투표 완료 또는 투표 수 초과 시 비활성화
                      onPressed: isDisabled
                          ? null
                          : () {
                              unawaited(
                                _confirmAndVote(context, ref, candidate),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVoted
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primary,
                        foregroundColor: isVoted
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(isVoted ? '투표 완료' : '선택'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndVote(
    BuildContext context,
    WidgetRef ref,
    UserProfile candidate,
  ) async {
    final confirmed = await context.showMinglitConfirm(
      title: '투표 확인',
      message: '${candidate.name}님에게 투표하시겠습니까?',
      confirmLabel: '투표하기',
    );

    if (confirmed) {
      await ref
          .read(matchingVoteControllerProvider.notifier)
          .vote(
            eventId: eventId,
            candidateId: candidate.id,
          );
    }
  }
}
