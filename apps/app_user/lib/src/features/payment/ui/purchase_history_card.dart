part of 'purchase_history_page.dart';

class PurchaseHistoryCard extends StatelessWidget {
  const PurchaseHistoryCard({required this.application, super.key});

  final EventApplication application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = application.event;
    final ticket = application.ticket;
    final party = event?.party;
    final location = event?.location ?? party?.location;
    final eventName = event?.title ?? party?.title ?? '제목 없음';
    final paymentAmount = application.paymentAmount;

    final formatter = NumberFormat('#,###');
    final dateLabel = event != null
        ? DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(event.startTime)
        : '-';

    return InkWell(
      onTap: () => PurchaseHistoryDetailRoute(
        applicationId: application.id,
      ).push<void>(context),
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: MinglitColors.textPrimary.withValues(
                alpha: MinglitOpacity.shadowXs,
              ),
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
                  // Fix #579: 구매일은 paidAt(실제 결제일)을 표시, 없으면 createdAt 폴백
                  // UTC → 로컬 변환 후 포맷 (KST 등에서 날짜 하루 차이 방지)
                  DateFormat('yyyy.MM.dd').format(
                    (application.paidAt ?? application.createdAt).toLocal(),
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Fix #638: StatusBadge를 공용 위젯으로 승격하여 재사용
                StatusBadge(status: application.status),
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
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Text(dateLabel, style: theme.textTheme.bodySmall),
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
          ],
        ),
      ),
    );
  }
}
