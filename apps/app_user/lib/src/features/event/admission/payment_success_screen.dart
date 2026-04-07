import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #453: event/home coordinator 직접 참조 제거 — 콜백으로 전환하여 순환 참조 해소
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    required this.event,
    required this.ticketId,
    required this.onViewTickets,
    required this.onBackToEvent,
    super.key,
  });

  final Event event;
  final String ticketId;
  final VoidCallback onViewTickets;
  final VoidCallback onBackToEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ticket = _findTicket();
    final formatter = NumberFormat('#,###');
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event.startTime);
    final location = event.location ?? event.party?.location;

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 완료'),
        leading: const CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 36,
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결제가 완료되었습니다! ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: MinglitSpacing.xxsmall),
                        Text(
                          '내 티켓에서 확인하실 수 있어요.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            Text(
              '티켓 요약',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: '이벤트',
                    value: event.title ?? '이벤트 정보 없음',
                  ),
                  _SummaryRow(
                    label: '일시',
                    value: dateLabel,
                  ),
                  _SummaryRow(
                    label: '장소',
                    value: location?.name ?? '장소 정보 없음',
                  ),
                  _SummaryRow(
                    label: '티켓',
                    value: ticket?.name ?? '티켓 정보 없음',
                  ),
                  _SummaryRow(
                    label: '결제 금액',
                    value: ticket == null
                        ? '-'
                        : '${formatter.format(ticket.price)}원',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewTickets,
                child: const Text('내 티켓 보기'),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBackToEvent,
                child: const Text('이벤트로 돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Ticket? _findTicket() {
    final tickets = event.tickets ?? [];
    for (final ticket in tickets) {
      if (ticket.id == ticketId) {
        return ticket;
      }
    }
    return null;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: MinglitSpacing.small),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: MinglitSpacing.small),
        ],
      ],
    );
  }
}
