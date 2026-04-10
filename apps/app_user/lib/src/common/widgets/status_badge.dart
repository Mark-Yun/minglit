import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #638: _StatusBadge → StatusBadge 공유 위젯 승격
/// purchase_history, my_tickets 등에서 상태 배지로 재사용
///
/// Fix #1236: 모든 상태에 brand purple 사용 → 의미론적 상태 색상으로 교정
/// paid/approved → success(초록), pending_review → warning(노랑),
/// pending → info(파랑), cancelled → neutral(회색), rejected → error(빨강)
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = '결제대기';
        // Fix #1236: info blue — 결제 완료를 기다리는 대기 상태
        color = MinglitColors.info;
      case 'pending_review':
        label = '심사중';
        // Fix #1236: warning amber — 심사 진행 중 (결과 미확정)
        color = MinglitColors.warning;
      case 'approved':
        label = '승인됨';
        // Fix #1236: success green — 긍정 상태
        color = MinglitColors.success;
      case 'paid':
        label = '결제완료';
        // Fix #1236: success green — 결제 완료된 긍정 상태
        color = MinglitColors.success;
      case 'rejected':
        label = '반려됨';
        color = MinglitColors.error;
      case 'cancelled':
        label = '취소됨';
        // Fix #1236: neutral grey — 취소는 오류가 아닌 종료 상태
        color = MinglitColors.textSecondary;
      default:
        label = '알수없음';
        color = MinglitColors.textSecondary;
    }

    // Fix #1236: MinglitChip(solid bg) → MinglitBadge(tinted bg + color text)
    // 브랜드 보라 단색 배경 제거, 상태별 틴트 배경 + 의미론적 텍스트 색 사용
    return MinglitBadge(
      label: label,
      color: color,
    );
  }
}
