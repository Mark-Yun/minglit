import 'package:app_user/src/features/payment/logic/purchase_history_detail_controller.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventApplicationReviewPage extends ConsumerWidget {
  const EventApplicationReviewPage({required this.applicationId, super.key});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(purchaseHistoryDetailProvider(applicationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('심사 상태'),
        centerTitle: false,
      ),
      body: MinglitAsyncValueWidget(
        value: appAsync,
        data: (application) {
          if (application == null) {
            return const Center(child: Text('신청 내역을 찾을 수 없습니다.'));
          }
          return _ReviewBody(application: application);
        },
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.application});

  final EventApplication application;

  @override
  Widget build(BuildContext context) {
    final event = application.event;
    final party = event?.party;
    final eventName = event?.title ?? party?.title ?? '제목 없음';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero card
          _ReviewCard(
            child: InkWell(
              onTap: event != null
                  ? () =>
                        EventDetailRoute(eventId: event.id).push<void>(context)
                  : null,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(MinglitRadius.small),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: MinglitImage(
                        path: event?.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event != null) ...[
                          const SizedBox(height: MinglitSpacing.xxsmall),
                          Text(
                            DateFormat(
                              'M월 d일 (E)',
                              'ko_KR',
                            ).format(event.startTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // 2. Timeline card
          _ReviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '심사 타임라인',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                _ApplicationTimeline(application: application),
              ],
            ),
          ),

          // Reapply CTA
          if (_canReapply(application.status)) ...[
            const SizedBox(height: MinglitSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: event != null
                    ? () => EventDetailRoute(
                        eventId: event.id,
                      ).push<void>(context)
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 신청하기'),
              ),
            ),
          ],

          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }

  bool _canReapply(String status) =>
      status == 'rejected' || status == 'payment_failed';
}

class _ApplicationTimeline extends StatelessWidget {
  const _ApplicationTimeline({required this.application});

  final EventApplication application;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _TimelineStep(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
        ],
      ],
    );
  }

  List<_StepData> _buildSteps() {
    final steps = <_StepData>[];

    // Step 1: 신청
    steps.add(
      _StepData(
        label: '신청',
        subtitle: DateFormat('yyyy.MM.dd HH:mm').format(
          application.createdAt.toLocal(),
        ),
        icon: Icons.edit_note,
        state: _StepState.done,
      ),
    );

    // Step 2: 결제
    if (application.status == 'pending') {
      steps.add(
        _StepData(
          label: '결제 대기 중',
          subtitle: '결제가 완료되면 심사가 시작됩니다.',
          icon: Icons.payment,
          state: _StepState.active,
        ),
      );
      return steps;
    }
    if (application.status == 'payment_failed') {
      steps.add(
        _StepData(
          label: '결제 실패',
          subtitle: '결제가 처리되지 않았습니다.',
          icon: Icons.payment,
          state: _StepState.failed,
        ),
      );
      return steps;
    }
    steps.add(
      _StepData(
        label: '결제 완료',
        subtitle: application.paidAt != null
            ? DateFormat('yyyy.MM.dd HH:mm').format(
                application.paidAt!.toLocal(),
              )
            : null,
        icon: Icons.payment,
        state: _StepState.done,
      ),
    );

    // Step 3: 심사 진행 / 결과
    switch (application.status) {
      case 'pending_review':
        steps.add(
          _StepData(
            label: '심사 진행 중',
            subtitle: '파트너가 신청을 검토하고 있습니다.',
            icon: Icons.hourglass_top,
            state: _StepState.active,
          ),
        );
      case 'approved':
        steps.add(
          _StepData(
            label: '승인됨',
            subtitle: application.rejectionReason,
            icon: Icons.check_circle,
            state: _StepState.done,
          ),
        );
      case 'paid':
        steps.add(
          _StepData(
            label: '예매 완료',
            subtitle: '이벤트 당일 체크인하세요.',
            icon: Icons.check_circle,
            state: _StepState.done,
          ),
        );
      case 'rejected':
        steps.add(
          _StepData(
            label: '반려됨',
            subtitle: application.rejectionReason,
            icon: Icons.cancel,
            state: _StepState.failed,
          ),
        );
      case 'cancelled':
        steps.add(
          _StepData(
            label: '취소됨',
            subtitle: null,
            icon: Icons.cancel,
            state: _StepState.neutral,
          ),
        );
    }

    return steps;
  }
}

enum _StepState { done, active, failed, neutral }

class _StepData {
  const _StepData({
    required this.label,
    required this.icon,
    required this.state,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final _StepState state;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final _StepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color dotColor;
    switch (step.state) {
      case _StepState.done:
        dotColor = theme.colorScheme.primary;
      case _StepState.active:
        dotColor = theme.colorScheme.tertiary;
      case _StepState.failed:
        dotColor = theme.colorScheme.error;
      case _StepState.neutral:
        dotColor = theme.colorScheme.onSurfaceVariant;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, size: 16, color: dotColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: MinglitSpacing.small),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : MinglitSpacing.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (step.subtitle != null && step.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      step.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
