import 'dart:async';

import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2127: EventApplicationReviewCarouselPage — groupId-filtered queue
// groupId provided → only that entry group's pending applications
// groupId null → all pending applications (backward-compatible)
class EventApplicationReviewCarouselPage extends ConsumerStatefulWidget {
  const EventApplicationReviewCarouselPage({
    required this.partyId,
    required this.eventId,
    this.startApplicationId,
    this.groupId,
    super.key,
  });

  final String partyId;
  final String eventId;
  final String? startApplicationId;
  final String? groupId;

  @override
  ConsumerState<EventApplicationReviewCarouselPage> createState() => _State();
}

class _State extends ConsumerState<EventApplicationReviewCarouselPage> {
  // Fix #2272: lazily initialized to set initialPage from startApplicationId
  PageController? _pageController;
  int _currentIndex = 0;
  bool _isLastMarked = false;

  PageController _getController(List<EventApplication> queue) {
    if (_pageController != null) return _pageController!;
    var startIdx = 0;
    if (widget.startApplicationId != null) {
      final idx = queue.indexWhere((a) => a.id == widget.startApplicationId);
      if (idx >= 0) startIdx = idx;
    }
    _currentIndex = startIdx;
    _pageController = PageController(initialPage: startIdx);
    return _pageController!;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _advance(List<EventApplication> queue) async {
    if (_currentIndex < queue.length - 1) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      unawaited(
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
      setState(() => _currentIndex++);
      return;
    }

    setState(() => _isLastMarked = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    EventApplicationReviewConfirmRoute(
      partyId: widget.partyId,
      eventId: widget.eventId,
    ).pushReplacement(context);
  }

  Future<void> _approve(List<EventApplication> queue, String applicationId) {
    // Fix #2272: local marking only — no server calls until confirm page
    ref
        .read(reviewMarkingsNotifierProvider.notifier)
        .addMark(applicationId, 'approved');
    return _advance(queue);
  }

  Future<void> _showRejectSheet(
    List<EventApplication> queue,
    String applicationId,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _RejectReasonSheet(),
    );
    // Fix #2272: null = user dismissed the sheet without confirming rejection
    if (!mounted || result == null) return;
    // Fix #2272: local marking only — no server calls until confirm page
    ref
        .read(reviewMarkingsNotifierProvider.notifier)
        .addMark(
          applicationId,
          'rejected',
          reason: result.isEmpty ? null : result,
        );
    await _advance(queue);
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(
      carouselQueueProvider(widget.eventId, widget.groupId),
    );

    return Scaffold(
      appBar: queueAsync.when(
        data: (queue) => _buildAppBar(context, queue.length),
        loading: () => _buildAppBar(context, null),
        error: (err, _) => _buildAppBar(context, null),
      ),
      body: queueAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Text(
            '오류 발생: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (queue) {
          if (queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64),
                  const SizedBox(height: MinglitSpacing.medium),
                  Text(
                    '심사 대기 중인 신청이 없습니다.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (_isLastMarked) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: MinglitColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 48,
                      color: MinglitColors.background,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '모든 신청 검토 완료',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최종 확인 화면으로 이동합니다…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _getController(queue),
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: queue.length,
                  itemBuilder: (_, i) => _ApplicantCard(application: queue[i]),
                ),
              ),
              _BottomCta(
                onApprove: () => _approve(queue, queue[_currentIndex].id),
                onReject: () =>
                    _showRejectSheet(queue, queue[_currentIndex].id),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, int? total) {
    // Fix #2272: total == 0 would show "1 / 0" — only show progress when queue is non-empty
    final progressText = (total != null && total > 0) ? '${_currentIndex + 1} / $total' : '';
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('심사'),
      actions: [
        if (progressText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: MinglitSpacing.medium),
            child: Center(
              child: Text(
                progressText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

String _formatDate(DateTime dt) => dt.toLocal().toString().substring(0, 10);

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application});

  final EventApplication application;

  @override
  Widget build(BuildContext context) {
    final user = application.user;
    final name = user?.name ?? '—';
    final gender = user?.gender;
    final birthYear = user?.birthYear;
    final subtitle = [
      if (gender != null) gender == 'male' ? '남성' : '여성',
      if (birthYear != null) '$birthYear년생',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MinglitSpacing.large),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                    : null,
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),
          const Divider(),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '신청일: ${_formatDate(application.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.onApprove,
    required this.onReject,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
          vertical: MinglitSpacing.medium,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                child: const Text('거절'),
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: FilledButton(
                onPressed: onApprove,
                child: const Text('승인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MinglitSpacing.screenEdge,
        MinglitSpacing.medium,
        MinglitSpacing.screenEdge,
        MediaQuery.viewInsetsOf(context).bottom + MinglitSpacing.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '거절 사유',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '거절 사유를 입력하세요 (선택)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('거절 확인'),
          ),
        ],
      ),
    );
  }
}
