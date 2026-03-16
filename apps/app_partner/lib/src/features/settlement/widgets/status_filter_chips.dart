import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (status, label) = _statuses[i];
          final isSelected = selectedStatus == status;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onStatusChanged(status),
          );
        },
      ),
    );
  }
}
