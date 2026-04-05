import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    required this.selectedStatus,
    required this.onStatusChanged,
    super.key,
  });

  final String? selectedStatus; // null = all
  final ValueChanged<String?> onStatusChanged;

  static const List<(String?, String)> _statuses = [
    (null, '전체'),
    ('PENDING', '대기'),
    ('READY', '확정'),
    ('PROCESSING', '지급중'),
    ('COMPLETED', '완료'),
    ('FAILED', '실패'),
    ('HOLD', '보류'),
    ('CANCELED', '취소'),
  ];

  @override
  Widget build(BuildContext context) {
    return MinglitChipGroup(
      children: [
        for (final (status, label) in _statuses)
          ChoiceChip(
            label: Text(label),
            selected: selectedStatus == status,
            onSelected: (_) => onStatusChanged(status),
          ),
      ],
    );
  }
}
