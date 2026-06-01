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
      appBar: AppBar(title: const Text('심사 상태'), centerTitle: false),
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
    return MinglitTimeline(children: _buildSteps(context));
  }

  List<MinglitTimelineStep> _buildSteps(BuildContext context) {
    final steps = <MinglitTimelineStep>[];

    // Step 1: 신청
    steps.add(
      _step(
        context,
        title: '신청',
        subtitle: DateFormat(
          'yyyy.MM.dd HH:mm',
        ).format(application.createdAt.toLocal()),
        tone: TimelineTone.success,
      ),
    );

    // Step 2: 결제
    if (application.status == 'pending') {
      steps.add(
        _step(
          context,
          title: '결제 대기 중',
          subtitle: '결제가 완료되면 심사가 시작됩니다.',
          tone: TimelineTone.progress,
          pulsing: true,
        ),
      );
      return steps;
    }
    if (application.status == 'payment_failed') {
      steps.add(
        _step(
          context,
          title: '결제 실패',
          subtitle: '결제가 처리되지 않았습니다.',
          tone: TimelineTone.error,
        ),
      );
      return steps;
    }
    steps.add(
      _step(
        context,
        title: '결제 완료',
        subtitle: application.paidAt != null
            ? DateFormat(
                'yyyy.MM.dd HH:mm',
              ).format(application.paidAt!.toLocal())
            : null,
        tone: TimelineTone.success,
      ),
    );

    // Step 3: 심사 진행 / 결과
    switch (application.status) {
      case 'pending_review':
        steps.add(
          _step(
            context,
            title: '심사 진행 중',
            subtitle: '파트너가 신청을 검토하고 있습니다.',
            tone: TimelineTone.progress,
            pulsing: true,
          ),
        );
      case 'approved':
        steps.add(
          _step(
            context,
            title: '승인됨',
            subtitle: application.rejectionReason,
            tone: TimelineTone.success,
          ),
        );
      case 'paid':
        steps.add(
          _step(
            context,
            title: '예매 완료',
            subtitle: '이벤트 당일 체크인하세요.',
            tone: TimelineTone.success,
          ),
        );
      case 'rejected':
        steps.add(
          _step(
            context,
            title: '반려됨',
            subtitle: application.rejectionReason,
            tone: TimelineTone.error,
          ),
        );
      case 'cancelled':
        steps.add(_step(context, title: '취소됨', tone: TimelineTone.neutral));
    }

    return steps;
  }

  MinglitTimelineStep _step(
    BuildContext context, {
    required String title,
    required TimelineTone tone,
    String? subtitle,
    bool pulsing = false,
  }) {
    final theme = Theme.of(context);
    return MinglitTimelineStep(
      tone: tone,
      title: title,
      pulsing: pulsing,
      child: subtitle == null || subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
