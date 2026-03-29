import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #638: _StatusBadge → StatusBadge 공유 위젯 승격
/// purchase_history, my_tickets 등에서 상태 배지로 재사용
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

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
