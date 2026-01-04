import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventDateTimeInput extends StatelessWidget {
  const EventDateTimeInput({
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    super.key,
  });

  final DateTime startTime;
  final DateTime endTime;
  final ValueChanged<DateTime> onStartTimeChanged;
  final ValueChanged<DateTime> onEndTimeChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Keep time, only update date
      final newStart = DateTime(
        picked.year,
        picked.month,
        picked.day,
        startTime.hour,
        startTime.minute,
      );
      final duration = endTime.difference(startTime);
      onStartTimeChanged(newStart);
      onEndTimeChanged(newStart.add(duration));
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final current = isStart ? startTime : endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked != null) {
      final newDateTime = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        onStartTimeChanged(newDateTime);
      } else {
        onEndTimeChanged(newDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(startTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selection Card
        _buildPickerCard(
          context,
          icon: Icons.calendar_today_outlined,
          label: '이벤트 날짜',
          value: dateStr,
          onTap: () => _pickDate(context),
        ),
        const SizedBox(height: MinglitSpacing.medium),

        // Time Selection Row
        Row(
          children: [
            Expanded(
              child: _buildPickerCard(
                context,
                icon: Icons.access_time,
                label: '시작 시간',
                value: DateFormat('HH:mm').format(startTime),
                onTap: () => _pickTime(context, true),
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: _buildPickerCard(
                context,
                icon: Icons.access_time_filled,
                label: '종료 시간',
                value: DateFormat('HH:mm').format(endTime),
                onTap: () => _pickTime(context, false),
              ),
            ),
          ],
        ),

        const SizedBox(height: MinglitSpacing.small),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.xsmall,
          ),
          child: Text(
            '총 ${endTime.difference(startTime).inHours}시간 '
            '${endTime.difference(startTime).inMinutes % 60}분 동안 진행됩니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
