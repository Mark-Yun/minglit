import 'package:app_partner/src/features/settlement/widgets/settlement_status_badge.dart';
import 'package:flutter/material.dart';

class SettlementCard extends StatelessWidget {
  const SettlementCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String? ?? 'PENDING';
    final netAmount = item['net_amount'] as int? ?? 0;
    final createdAt = item['created_at'] as String? ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '정산 항목',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt.isNotEmpty ? createdAt.substring(0, 10) : '-',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₩${_formatAmount(netAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SettlementStatusBadge(
              status: SettlementStatus.fromString(status),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return amount < 0 ? '-$buffer' : buffer.toString();
  }
}
