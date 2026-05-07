import 'package:app_user/src/common/widgets/status_badge.dart';
import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/logic/purchase_history_detail_controller.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseHistoryDetailPage extends ConsumerWidget {
  const PurchaseHistoryDetailPage({required this.applicationId, super.key});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(purchaseHistoryDetailProvider(applicationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 상세'),
        centerTitle: false,
      ),
      body: MinglitAsyncValueWidget(
        value: appAsync,
        data: (application) {
          if (application == null) {
            return const Center(child: Text('구매 내역을 찾을 수 없습니다.'));
          }
          return _PurchaseDetailBody(application: application);
        },
      ),
    );
  }
}

class _PurchaseDetailBody extends ConsumerWidget {
  const _PurchaseDetailBody({required this.application});

  final EventApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(purchaseHistoryControllerProvider.notifier);
    final event = application.event;
    final ticket = application.ticket;
    final party = event?.party;
    final location = event?.location ?? party?.location;
    final eventName = event?.title ?? party?.title ?? '제목 없음';
    final paymentId = application.paymentId;
    final paymentAmount = application.paymentAmount ?? 0;
    final canCancel = controller.canCancel(application);
    final isRefunded = application.refundStatus == 'completed';
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero card
          _DetailCard(
            child: InkWell(
              onTap: event != null
                  ? () =>
                        EventDetailRoute(eventId: event.id).push<void>(context)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(MinglitRadius.small),
                      child: MinglitImage(
                        path: event?.imageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  Text(
                    eventName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event != null) ...[
                    const SizedBox(height: MinglitSpacing.xsmall),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: MinglitSpacing.xxsmall),
                        Text(
                          DateFormat(
                            'M월 d일 (E) HH:mm',
                            'ko_KR',
                          ).format(event.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (location != null) ...[
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: MinglitSpacing.xxsmall),
                        Expanded(
                          child: Text(
                            location.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // 2. Review status row (tappable → review timeline)
          _DetailCard(
            child: InkWell(
              onTap: () => EventApplicationReviewRoute(
                applicationId: applicationId,
              ).push<void>(context),
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.xsmall,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '심사 상태',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: MinglitSpacing.xxsmall),
                          Row(
                            children: [
                              StatusBadge(status: application.status),
                              if (isRefunded) ...[
                                const SizedBox(width: MinglitSpacing.xsmall),
                                _RefundBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: MinglitSpacing.xxsmall),
                          Text(
                            DateFormat('yyyy.MM.dd HH:mm').format(
                              application.updatedAt.toLocal(),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // 3. Payment info card
          if (!isRefunded) ...[
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '결제 정보',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  _KeyValueRow(
                    label: '결제일',
                    value: DateFormat('yyyy.MM.dd').format(
                      (application.paidAt ?? application.createdAt).toLocal(),
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  _KeyValueRow(
                    label: '티켓',
                    value: ticket?.name ?? '티켓 정보 없음',
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  _KeyValueRow(
                    label: '결제금액',
                    value: '${formatter.format(paymentAmount)}원',
                    isHighlight: true,
                  ),
                  if (paymentId != null || paymentAmount == 0) ...[
                    const SizedBox(height: MinglitSpacing.medium),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (paymentId != null && paymentId.isNotEmpty) {
                          final url = Uri.parse(
                            'https://service.iamport.kr/payments/detail/$paymentId',
                          );
                          final launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched && context.mounted) {
                            context.showMinglitWarning(
                              '영수증 페이지를 열 수 없습니다.',
                            );
                          }
                        } else {
                          context.showMinglitInfo('무료 티켓 — 결제 영수증이 없습니다.');
                        }
                      },
                      icon: const Icon(Icons.receipt_outlined, size: 18),
                      label: const Text('영수증 보기'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
          ],

          // Refund info card (shows instead of payment info when refunded)
          if (isRefunded) ...[
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '환불 정보',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  _KeyValueRow(
                    label: '결제금액',
                    value: '${formatter.format(paymentAmount)}원',
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  _KeyValueRow(
                    label: '환불금액',
                    value: '${formatter.format(paymentAmount)}원',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
          ],

          // 4. Refund policy card with cancel button
          if (!isRefunded) ...[
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '취소 및 환불 정책',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  Text(
                    '이벤트 시작 전까지 취소 가능합니다. 환불 정책은 결제 시 안내된 내용을 따릅니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canCancel
                          ? () => _runCancel(context, ref, event)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCancel
                            ? Theme.of(context).colorScheme.errorContainer
                            : null,
                        foregroundColor: canCancel
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : null,
                      ),
                      child: const Text('예매 취소'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
          ],

          // 5. Partner info card
          if (party != null) ...[
            _PartnerInfoCard(party: party),
            const SizedBox(height: MinglitSpacing.medium),
          ],
        ],
      ),
    );
  }

  String get applicationId => application.id;

  Future<void> _runCancel(
    BuildContext context,
    WidgetRef ref,
    Event? event,
  ) async {
    if (event == null) return;
    final controller = ref.read(purchaseHistoryControllerProvider.notifier);
    await controller.runRefundFlow(
      eventId: event.id,
      paymentId: application.paymentId,
      paymentAmount: application.paymentAmount,
      eventStartTime: event.startTime,
      paidAt: application.paidAt,
      showMissingInfo: () async {
        if (context.mounted) context.showMinglitWarning('취소에 필요한 정보가 부족합니다.');
      },
      showNotEligible: () async {
        if (context.mounted) context.showMinglitWarning('환불 기간이 지났습니다.');
      },
      confirmRefund: (calculation) async {
        if (!context.mounted) return false;
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('예매 취소'),
                content: Text(
                  '${NumberFormat('#,###').format(calculation.refundAmount)}원이 환불됩니다. 취소하시겠습니까?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('아니오'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('취소하기'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      showError: (message) async {
        if (!context.mounted) return false;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('취소 실패'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        return false;
      },
      onSuccess: () async {
        if (context.mounted) {
          context.showMinglitSuccess('예매가 취소되었습니다.');
          Navigator.pop(context);
        }
      },
    );
  }
}

class _PartnerInfoCard extends StatelessWidget {
  const _PartnerInfoCard({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DetailCard(
      child: InkWell(
        onTap: () => PartnerDetailRoute(partnerId: party.partnerId).push<void>(
          context,
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: party.imageUrl != null
                  ? NetworkImage(party.imageUrl!)
                  : null,
              child: party.imageUrl == null
                  ? Icon(Icons.store, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

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

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RefundBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.xsmall,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Text(
        '환불완료',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
