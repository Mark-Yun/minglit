import 'dart:async';

import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2127: EventApplicationReviewCarouselPage — groupId-filtered queue
// groupId provided → only that entry group's pending applications
// groupId null → all pending applications (backward-compatible)
class EventApplicationReviewCarouselPage extends ConsumerStatefulWidget {
  const EventApplicationReviewCarouselPage({
    required this.eventId,
    this.startApplicationId,
    this.groupId,
    super.key,
  });
  final String eventId;
  final String? startApplicationId;
  final String? groupId;

  @override
  ConsumerState<EventApplicationReviewCarouselPage> createState() => _State();
}

class _State extends ConsumerState<EventApplicationReviewCarouselPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advance(List<EventApplication> queue) async {
    if (_currentIndex >= queue.length - 1) {
      if (mounted) setState(() => _isDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    unawaited(
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
    if (mounted) setState(() => _currentIndex++);
  }

  Future<void> _review(
    List<EventApplication> queue,
    String applicationId,
    String status, {
    String? reason,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(eventApplicationReviewControllerProvider.notifier)
          .reviewApplication(
            applicationId: applicationId,
            status: status,
            reason: reason,
          );
      await _advance(queue);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showRejectSheet(
    List<EventApplication> queue,
    String applicationId,
  ) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _RejectReasonSheet(),
    );
    if (!mounted) return;
    await _review(queue, applicationId, 'rejected', reason: reason);
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
          if (_isDone) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  Text(
                    '심사 완료',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: queue.length,
                  itemBuilder: (_, i) => _ApplicantCard(application: queue[i]),
                ),
              ),
              _BottomCta(
                isSubmitting: _isSubmitting,
                onApprove: () => _review(
                  queue,
                  queue[_currentIndex].id,
                  'approved',
                ),
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
    final progressText = total != null ? '${_currentIndex + 1} / $total' : '';
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
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
  });
  final bool isSubmitting;
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
                onPressed: isSubmitting ? null : onReject,
                child: const Text('거절'),
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: FilledButton(
                onPressed: isSubmitting ? null : onApprove,
                child: isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('승인'),
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
