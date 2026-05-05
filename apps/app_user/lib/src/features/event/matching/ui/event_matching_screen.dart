import 'dart:async';

import 'package:app_user/src/features/event/matching/logic/commit_match_likes_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

const _maxSelectionCount = 3;
const _rowEntranceStep = Duration(milliseconds: 40);
const _rowEntranceDuration = Duration(milliseconds: 320);
const _rowTintDuration = Duration(milliseconds: 240);
const _checkBounceDuration = Duration(milliseconds: 320);

class EventMatchingScreen extends ConsumerStatefulWidget {
  const EventMatchingScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventMatchingScreen> createState() =>
      _EventMatchingScreenState();
}

class _EventMatchingScreenState extends ConsumerState<EventMatchingScreen> {
  final Set<String> _selectedCandidateIds = <String>{};

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(commitMatchLikesControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        handleMinglitError(context, next.error!, next.stackTrace);
        return;
      }
      if (previous?.isLoading == true && next.hasValue) {
        _showSubmittedPage(context);
      }
    });

    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final candidatesAsync = ref.watch(matchCandidatesProvider(widget.eventId));
    final mutationState = ref.watch(commitMatchLikesControllerProvider);
    final body = _buildBody(eventAsync, candidatesAsync, mutationState);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '이벤트 매칭'),
      bottomNavigationBar: _buildBottomBar(mutationState),
      body: SafeArea(
        bottom: false,
        child: body,
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<Event> eventAsync,
    AsyncValue<List<UserProfile>> candidatesAsync,
    AsyncValue<void> mutationState,
  ) {
    if (eventAsync.isLoading || candidatesAsync.isLoading) {
      return const _LoadingState();
    }
    if (eventAsync.hasError) {
      return MinglitErrorState(
        icon: Icons.error_outline_rounded,
        title: '매칭 화면을 불러올 수 없어요',
        subtitle: '${eventAsync.error}',
        retryLabel: '다시 시도',
        onRetry: () {
          ref
            ..invalidate(eventDetailProvider(widget.eventId))
            ..invalidate(matchCandidatesProvider(widget.eventId));
        },
      );
    }
    if (candidatesAsync.hasError) {
      return MinglitErrorState(
        icon: Icons.error_outline_rounded,
        title: '매칭 후보를 불러올 수 없어요',
        subtitle: '${candidatesAsync.error}',
        retryLabel: '다시 시도',
        onRetry: () => ref.invalidate(matchCandidatesProvider(widget.eventId)),
      );
    }
    return _buildLoadedState(
      context,
      eventAsync.requireValue,
      candidatesAsync.requireValue,
      mutationState,
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    Event event,
    List<UserProfile> candidates,
    AsyncValue<void> mutationState,
  ) {
    if (_isEnded(event)) {
      return const _EndedState();
    }

    final sortedCandidates = [...candidates]
      ..sort((a, b) => a.name.compareTo(b.name));

    if (sortedCandidates.isEmpty) {
      return const _EmptyState();
    }

    final theme = Theme.of(context);
    final selectedCount = _selectedCandidateIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MinglitSpacing.screenEdge,
            MinglitSpacing.medium,
            MinglitSpacing.screenEdge,
            MinglitSpacing.small,
          ),
          child: Text(
            '좋아요를 보낸 사람과 매치되면 결과 화면에서 서로의 연락처를 알려드려요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.screenEdge,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(MinglitRadius.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.sm,
                  vertical: MinglitSpacing.xsmall,
                ),
                child: Text(
                  selectedCount == 0 ? '최대 3명' : '$selectedCount명 선택됨',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selectedCount == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.large),
            itemCount: sortedCandidates.length,
            itemBuilder: (context, index) {
              final candidate = sortedCandidates[index];
              final isSelected = _selectedCandidateIds.contains(candidate.id);
              return _CandidateRow(
                key: ValueKey(candidate.id),
                candidate: candidate,
                index: index,
                isSelected: isSelected,
                onTap: () => _toggleSelection(context, candidate.id),
              );
            },
          ),
        ),
        if (mutationState.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: MinglitSpacing.small),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildBottomBar(AsyncValue<void> mutationState) {
    final selectedCount = _selectedCandidateIds.length;
    final hasSelection = selectedCount > 0;
    final ctaLabel = hasSelection ? '확인 ($selectedCount명)' : '확인';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasSelection)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
              vertical: MinglitSpacing.small,
            ),
            child: Text(
              '서로 좋아요가 맞아야 결과가 공개돼요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        MinglitBottomCTA(
          label: ctaLabel,
          enabled: hasSelection && !mutationState.isLoading,
          onPressed: hasSelection && !mutationState.isLoading
              ? _submitSelection
              : null,
        ),
      ],
    );
  }

  bool _isEnded(Event event) {
    return event.status == 'completed' || event.status == 'cancelled';
  }

  Future<void> _submitSelection() async {
    final selectedCount = _selectedCandidateIds.length;
    final confirmed = await MinglitAlert.showConfirm(
      context: context,
      title: '$selectedCount명에게 좋아요를 보낼게요',
      content: '전송 후에는 선택을 바꿀 수 없어요.',
      confirmText: '보내기',
      cancelText: '취소',
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(commitMatchLikesControllerProvider.notifier)
        .commit(
          eventId: widget.eventId,
          candidateIds: _selectedCandidateIds.toList(growable: false),
        );
  }

  void _toggleSelection(BuildContext context, String candidateId) {
    setState(() {
      if (_selectedCandidateIds.contains(candidateId)) {
        _selectedCandidateIds.remove(candidateId);
        return;
      }
      if (_selectedCandidateIds.length >= _maxSelectionCount) {
        // Fix #2206: The v2 spec caps local pre-submit selection at 3,
        // so block the 4th tap instead of letting the server reject it.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 3명까지 선택할 수 있어요.')),
        );
        return;
      }
      _selectedCandidateIds.add(candidateId);
    });
  }

  Future<void> _showSubmittedPage(BuildContext context) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => MinglitConfirmationPage(
          title: '좋아요를 보냈어요',
          description: '서로 마음이 맞으면 결과 화면에서 바로 알려드릴게요.',
          icon: Icons.check_rounded,
          tone: MinglitConfirmationTone.success,
          ctaLabel: '닫기',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.medium,
      ),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: MinglitSpacing.medium),
      itemBuilder: (context, index) => const _SkeletonRow(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return MinglitEmptyState(
      icon: Icons.people_outline_rounded,
      title: '지금은 선택할 후보가 없어요',
      subtitle: '이벤트 현장에서 만난 사람이 아직 준비되지 않았어요.',
      actionLabel: '닫기',
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}

class _EndedState extends StatelessWidget {
  const _EndedState();

  @override
  Widget build(BuildContext context) {
    return MinglitEmptyState(
      icon: Icons.lock_outline_rounded,
      title: '매칭 선택이 종료되었어요',
      subtitle: '개인정보 보호를 위해 이 화면에서는 후보 목록을 더 이상 보여주지 않아요.',
      actionLabel: '닫기',
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final avatarSize = MinglitSpacing.xlarge + MinglitSpacing.large;
    final trailingSize = MinglitSpacing.xlarge + MinglitSpacing.sm;
    return Row(
      children: [
        MinglitSkeleton(
          width: avatarSize,
          height: avatarSize,
          borderRadius: BorderRadius.circular(avatarSize / 2),
        ),
        const SizedBox(width: MinglitSpacing.medium),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinglitSkeleton(
                width: double.infinity,
                height: MinglitSpacing.medium,
              ),
              SizedBox(height: MinglitSpacing.small),
              MinglitSkeleton(
                width: MinglitSpacing.xxlarge + MinglitSpacing.xlarge,
                height: MinglitSpacing.sm,
              ),
            ],
          ),
        ),
        const SizedBox(width: MinglitSpacing.medium),
        MinglitSkeleton(
          width: trailingSize,
          height: trailingSize,
          borderRadius: BorderRadius.circular(trailingSize / 2),
        ),
      ],
    );
  }
}

class _CandidateRow extends StatefulWidget {
  const _CandidateRow({
    required this.candidate,
    required this.index,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final UserProfile candidate;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CandidateRow> createState() => _CandidateRowState();
}

class _CandidateRowState extends State<_CandidateRow>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _checkController;
  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: _rowEntranceDuration,
    );
    _checkController = AnimationController(
      vsync: this,
      duration: _checkBounceDuration,
      value: widget.isSelected ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _entranceController.value = 1;
      _checkController.value = widget.isSelected ? 1 : 0;
      return;
    }
    _entranceTimer ??= Timer(
      _rowEntranceStep * widget.index,
      _entranceController.forward,
    );
  }

  @override
  void didUpdateWidget(covariant _CandidateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _checkController
        ..value = 0
        ..forward();
    }
    if (oldWidget.isSelected && !widget.isSelected) {
      _checkController.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _entranceController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = MinglitSpacing.xlarge + MinglitSpacing.large;
    final trailingSize = MinglitSpacing.xlarge + MinglitSpacing.sm;
    final checkCircleSize = MinglitSpacing.large + MinglitSpacing.xsmall;
    final selectedBackground = theme.colorScheme.primary.withValues(
      alpha: 0.06,
    );
    final meta = widget.candidate.username.isNotEmpty
        ? '@${widget.candidate.username}'
        : '프로필 정보 준비 중';

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _checkController]),
      builder: (context, _) {
        final entranceValue = Curves.easeOutCubic.transform(
          _entranceController.value,
        );
        final bounceScale =
            Tween<double>(
              begin: 0.8,
              end: 1,
            ).transform(
              CurvedAnimation(
                parent: _checkController,
                curve: const Cubic(0.34, 1.56, 0.64, 1),
              ).value,
            );

        return Opacity(
          opacity: entranceValue,
          child: Transform.translate(
            offset: Offset(0, (1 - entranceValue) * MinglitSpacing.small),
            child: AnimatedContainer(
              duration: _rowTintDuration,
              curve: Curves.easeInOut,
              color: widget.isSelected
                  ? selectedBackground
                  : MinglitColors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.screenEdge,
                    vertical: MinglitSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                        ),
                        child: Text(
                          widget.candidate.name.characters.first,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: MinglitSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.candidate.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: MinglitSpacing.xxsmall),
                            Text(
                              meta,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: MinglitSpacing.medium),
                      SizedBox(
                        width: trailingSize,
                        height: trailingSize,
                        child: Center(
                          child: Transform.scale(
                            scale: widget.isSelected ? bounceScale : 1,
                            child: Container(
                              width: checkCircleSize,
                              height: checkCircleSize,
                              decoration: BoxDecoration(
                                color: widget.isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  checkCircleSize / 2,
                                ),
                                border: Border.all(
                                  color: widget.isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Icon(
                                widget.isSelected
                                    ? Icons.check_rounded
                                    : Icons.circle_outlined,
                                size: MinglitIconSize.xsmall,
                                color: widget.isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
