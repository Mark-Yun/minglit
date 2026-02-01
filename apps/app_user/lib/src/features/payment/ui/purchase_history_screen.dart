import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchaseHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 내역'),
      ),
      body: MinglitAsyncValueWidget(
        value: historyAsync,
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(
                '구매 내역이 없습니다.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: history.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              return PurchaseHistoryCard(application: history[index]);
            },
          );
        },
      ),
    );
  }
}

class PurchaseHistoryCard extends ConsumerWidget {
  const PurchaseHistoryCard({required this.application, super.key});

  final EventApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final event = application.event;
    final ticket = application.ticket;
    final party = event?.party;
    final location = event?.location ?? party?.location;
    final eventName = event?.title ?? party?.title ?? '제목 없음';
    final paymentAmount = application.paymentAmount;
    final paymentId = application.paymentId;
    final eventStartTime = event?.startTime;
    final contactOptions = (event?.contactOptions.isNotEmpty ?? false)
        ? event!.contactOptions
        : party?.contactOptions ?? <String, dynamic>{};

    final formatter = NumberFormat('#,###');
    final dateLabel = event != null
        ? DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(event.startTime)
        : '-';

    final isActiveTicket =
        application.status == 'paid' || application.status == 'approved';
    final isRefundReady =
        paymentId != null && paymentAmount != null && eventStartTime != null;
    final canCancel =
        isActiveTicket && isRefundReady && application.refundStatus == 'none';

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy.MM.dd').format(application.createdAt),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              _StatusBadge(status: application.status),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // 2. Event Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(MinglitRadius.small),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: MinglitImage(
                    path: event?.imageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      location?.name ?? '장소 정보 없음',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: MinglitSpacing.xlarge),

          // 3. Ticket & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket?.name ?? '티켓 정보 없음',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${formatter.format(paymentAmount ?? 0)}원',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // 4. Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    if (paymentId == null || paymentId.isEmpty) {
                      context.showMinglitWarning('영수증 정보를 확인할 수 없습니다.');
                      return;
                    }

                    final receiptUrl = Uri.parse(
                      'https://service.iamport.kr/payments/detail/$paymentId',
                    );

                    final launched = await launchUrl(
                      receiptUrl,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!launched && context.mounted) {
                      context.showMinglitWarning('영수증 페이지를 열 수 없습니다.');
                    }
                  },
                  child: const Text('영수증'),
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final phone =
                        _resolveContactValue(
                          contactOptions,
                          'phone',
                        ) ??
                        party?.partner?.contactPhone;
                    final email =
                        _resolveContactValue(
                          contactOptions,
                          'email',
                        ) ??
                        party?.partner?.contactEmail;

                    Uri? uri;
                    if (phone != null && phone.isNotEmpty) {
                      uri = Uri.parse('tel:$phone');
                    } else if (email != null && email.isNotEmpty) {
                      uri = Uri.parse('mailto:$email');
                    }

                    if (uri == null) {
                      context.showMinglitWarning('연락처 정보가 없습니다.');
                      return;
                    }

                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!launched && context.mounted) {
                      context.showMinglitWarning('연락처를 열 수 없습니다.');
                    }
                  },
                  child: const Text('문의하기'),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onCancelPressed(
                      context: context,
                      ref: ref,
                      eventName: eventName,
                      paymentId: paymentId,
                      paymentAmount: paymentAmount,
                      eventStartTime: eventStartTime,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text('예매 취소'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String? _resolveContactValue(
    Map<String, dynamic> contactOptions,
    String key,
  ) {
    final value = contactOptions[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  Future<void> _onCancelPressed({
    required BuildContext context,
    required WidgetRef ref,
    required String eventName,
    required String? paymentId,
    required int? paymentAmount,
    required DateTime? eventStartTime,
  }) async {
    if (paymentId == null || paymentAmount == null || eventStartTime == null) {
      await context.showMinglitAlert(
        title: '환불 정보를 확인할 수 없습니다',
        message: '결제 정보를 다시 확인해주세요.',
      );
      return;
    }

    final calculation = RefundCalculator.calculate(
      eventStartTime: eventStartTime,
      paymentAmount: paymentAmount,
    );

    final confirmed = await _showRefundConfirmDialog(
      context: context,
      eventName: eventName,
      paymentAmount: paymentAmount,
      calculation: calculation,
    );

    if (!confirmed || !context.mounted) return;

    await _requestRefund(
      context: context,
      ref: ref,
      paymentId: paymentId,
      calculation: calculation,
    );
  }

  Future<void> _requestRefund({
    required BuildContext context,
    required WidgetRef ref,
    required String paymentId,
    required RefundCalculation calculation,
  }) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref
          .read(eventRepositoryProvider)
          .cancelPayment(
            paymentId: paymentId,
            refundAmount: calculation.refundAmount,
            reason: '사용자 예매 취소',
          );

      ref.invalidate(purchaseHistoryControllerProvider);
      if (!context.mounted) return;
      context.showMinglitSuccess('예매가 취소되었습니다.');
      await Navigator.of(context).maybePop();
    } on Object catch (e, st) {
      if (!context.mounted) return;
      final exception = MinglitException.from(e, st);
      final message = exception is MinglitSystemException
          ? exception.userMessage
          : exception.message;
      final retry = await _showRefundErrorDialog(
        context: context,
        message: message,
      );
      if (retry && context.mounted) {
        await _requestRefund(
          context: context,
          ref: ref,
          paymentId: paymentId,
          calculation: calculation,
        );
      }
    } finally {
      loading.hide();
    }
  }

  Future<bool> _showRefundConfirmDialog({
    required BuildContext context,
    required String eventName,
    required int paymentAmount,
    required RefundCalculation calculation,
  }) async {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    final result = await MinglitDialog.show<bool>(
      context: context,
      title: '예매 취소 확인',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _RefundRow(
            label: '결제 금액',
            value: '${formatter.format(paymentAmount)}원',
          ),
          _RefundRow(
            label: '환불 비율',
            value: '${calculation.refundPercentage}%',
          ),
          _RefundRow(
            label: '환불 금액',
            value: '${formatter.format(calculation.refundAmount)}원',
          ),
          _RefundRow(
            label: '수수료',
            value: '${formatter.format(calculation.feeAmount)}원',
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '환불 수수료는 취소 시점에 따라 달라집니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('닫기'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
          child: const Text('예매 취소'),
        ),
      ],
    );

    return result ?? false;
  }

  Future<bool> _showRefundErrorDialog({
    required BuildContext context,
    required String message,
  }) async {
    final result = await MinglitDialog.show<bool>(
      context: context,
      title: '환불 처리 실패',
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('닫기'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('다시 시도'),
        ),
      ],
    );

    return result ?? false;
  }
}

class _RefundRow extends StatelessWidget {
  const _RefundRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.xsmall),
      child: Row(
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = '결제대기';
        color = theme.colorScheme.outline;
      case 'pending_review':
        label = '심사중';
        color = theme.colorScheme.tertiary;
      case 'approved':
        label = '승인됨';
        color = theme.colorScheme.primary;
      case 'paid':
        label = '결제완료';
        color = theme.colorScheme.primary;
      case 'rejected':
        label = '반려됨';
        color = theme.colorScheme.error;
      case 'cancelled':
        label = '취소됨';
        color = theme.colorScheme.error;
      default:
        label = '알수없음';
        color = theme.colorScheme.outline;
    }

    return MinglitChip(
      label: label,
      color: color,
    );
  }
}
