import 'package:flutter/material.dart';

enum SettlementStatus {
  pending,
  hold,
  ready,
  processing,
  completed,
  failed,
  canceled
  ;

  static SettlementStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'PENDING' => SettlementStatus.pending,
      'HOLD' => SettlementStatus.hold,
      'READY' => SettlementStatus.ready,
      'PROCESSING' => SettlementStatus.processing,
      'COMPLETED' => SettlementStatus.completed,
      'FAILED' => SettlementStatus.failed,
      'CANCELED' => SettlementStatus.canceled,
      _ => SettlementStatus.pending,
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
  };

  Color get backgroundColor => switch (this) {
    SettlementStatus.pending => const Color(0xFFE0E0E0),
    SettlementStatus.hold => const Color(0xFFFFF3E0),
    SettlementStatus.ready => const Color(0xFFE3F2FD),
    SettlementStatus.processing => const Color(0xFFE8EAF6),
    SettlementStatus.completed => const Color(0xFFE8F5E9),
    SettlementStatus.failed => const Color(0xFFFFEBEE),
    SettlementStatus.canceled => const Color(0xFFF5F5F5),
  };

  Color get textColor => switch (this) {
    SettlementStatus.pending => const Color(0xFF616161),
    SettlementStatus.hold => const Color(0xFFE65100),
    SettlementStatus.ready => const Color(0xFF1565C0),
    SettlementStatus.processing => const Color(0xFF283593),
    SettlementStatus.completed => const Color(0xFF1B5E20),
    SettlementStatus.failed => const Color(0xFFB71C1C),
    SettlementStatus.canceled => const Color(0xFF9E9E9E),
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
    final isStrikethrough = status == SettlementStatus.canceled;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: status.textColor,
          decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          decorationColor: isStrikethrough ? status.textColor : null,
        ),
      ),
    );
  }
}
