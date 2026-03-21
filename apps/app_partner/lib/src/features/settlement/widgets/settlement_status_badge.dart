import 'package:flutter/material.dart';

enum SettlementStatus {
  pending,
  hold,
  ready,
  processing,
  completed,
  failed,
  canceled,
  unknown;

  static SettlementStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'PENDING' => SettlementStatus.pending,
      'HOLD' => SettlementStatus.hold,
      'READY' => SettlementStatus.ready,
      'PROCESSING' => SettlementStatus.processing,
      'COMPLETED' => SettlementStatus.completed,
      'FAILED' => SettlementStatus.failed,
      'CANCELED' => SettlementStatus.canceled,
      _ => SettlementStatus.unknown,
    };
  }

  String get label => switch (this) {
        SettlementStatus.pending => '정산 대기',
        SettlementStatus.hold => '보류',
        SettlementStatus.ready => '정산 확정',
        SettlementStatus.processing => '지급 중',
        SettlementStatus.completed => '지급 완료',
        SettlementStatus.failed => '지급 실패',
        SettlementStatus.canceled => '취소',
        SettlementStatus.unknown => '알 수 없음',
      };

  Color backgroundColor(ColorScheme colorScheme) => switch (this) {
        SettlementStatus.pending => colorScheme.surfaceContainerHighest,
        SettlementStatus.hold => colorScheme.errorContainer,
        SettlementStatus.ready => colorScheme.primaryContainer,
        SettlementStatus.processing => colorScheme.secondaryContainer,
        SettlementStatus.completed => colorScheme.tertiaryContainer,
        SettlementStatus.failed => colorScheme.errorContainer,
        SettlementStatus.canceled => colorScheme.surfaceContainerLow,
        SettlementStatus.unknown => colorScheme.surfaceContainerHighest,
      };

  Color textColor(ColorScheme colorScheme) => switch (this) {
        SettlementStatus.pending => colorScheme.onSurfaceVariant,
        SettlementStatus.hold => colorScheme.error,
        SettlementStatus.ready => colorScheme.primary,
        SettlementStatus.processing => colorScheme.secondary,
        SettlementStatus.completed => colorScheme.tertiary,
        SettlementStatus.failed => colorScheme.error,
        SettlementStatus.canceled => colorScheme.outline,
        SettlementStatus.unknown => colorScheme.onSurfaceVariant,
      };
}

class SettlementStatusBadge extends StatelessWidget {
  const SettlementStatusBadge({
    required this.status,
    super.key,
    this.compact = true,
  });

  final SettlementStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isStrikethrough = status == SettlementStatus.canceled;
    final bgColor = status.backgroundColor(colorScheme);
    final textCol = status.textColor(colorScheme);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: textCol,
          decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          decorationColor: isStrikethrough ? textCol : null,
        ),
      ),
    );
  }
}
