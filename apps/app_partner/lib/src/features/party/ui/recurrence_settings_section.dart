import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// UI section for configuring recurrence settings during event creation.
///
/// Displays a toggle and, when enabled, pattern/day/month-day controls plus
/// a preview of the next upcoming dates.
///
/// The widget reads [recurrenceSettingsControllerProvider] from the nearest
/// [ProviderScope].
class RecurrenceSettingsSection extends ConsumerWidget {
  const RecurrenceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurrenceSettingsControllerProvider);
    final notifier = ref.read(recurrenceSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('반복 일정'),
          subtitle: state.isEnabled ? null : const Text('정기적으로 이벤트를 자동 생성합니다'),
          value: state.isEnabled,
          onChanged: (_) => notifier.toggle(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
          ),
        ),
        if (state.isEnabled) ...[
          const Divider(height: 1),
          _PatternChips(state: state, notifier: notifier),
          if (state.pattern == RecurrencePattern.monthly) ...[
            const SizedBox(height: MinglitSpacing.small),
            _MonthDayInput(state: state, notifier: notifier),
          ] else ...[
            const SizedBox(height: MinglitSpacing.small),
            _DayOfWeekChips(state: state, notifier: notifier),
          ],
          const SizedBox(height: MinglitSpacing.small),
          _EndDateRow(state: state, notifier: notifier),
          const SizedBox(height: MinglitSpacing.medium),
          _PreviewDates(notifier: notifier),
        ],
      ],
    );
  }
}

// ─── Sub-widgets ───

class _PatternChips extends StatelessWidget {
  const _PatternChips({required this.state, required this.notifier});

  final RecurrenceSettingsState state;
  final RecurrenceSettingsController notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MinglitSpacing.small),
          Text('반복 주기', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: MinglitSpacing.xsmall),
          Wrap(
            spacing: MinglitSpacing.xsmall,
            children: [
              _patternChip(context, RecurrencePattern.weekly, '매주'),
              _patternChip(context, RecurrencePattern.biweekly, '격주'),
              _patternChip(context, RecurrencePattern.monthly, '매월'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patternChip(BuildContext context, RecurrencePattern p, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: state.pattern == p,
      onSelected: (_) => notifier.setPattern(p),
    );
  }
}

class _DayOfWeekChips extends StatelessWidget {
  const _DayOfWeekChips({required this.state, required this.notifier});

  final RecurrenceSettingsState state;
  final RecurrenceSettingsController notifier;

  static const _days = [
    (0, '일'),
    (1, '월'),
    (2, '화'),
    (3, '수'),
    (4, '목'),
    (5, '금'),
    (6, '토'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('요일 선택', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: MinglitSpacing.xsmall),
          Wrap(
            spacing: MinglitSpacing.xsmall,
            children: _days.map((d) {
              final (jsDay, label) = d;
              return FilterChip(
                label: Text(label),
                selected: state.daysOfWeek.contains(jsDay),
                onSelected: (_) => notifier.toggleDay(jsDay),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthDayInput extends StatelessWidget {
  const _MonthDayInput({required this.state, required this.notifier});

  final RecurrenceSettingsState state;
  final RecurrenceSettingsController notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('매월 반복일', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: MinglitSpacing.xsmall),
          DropdownButtonFormField<int>(
            initialValue: state.monthDay,
            hint: const Text('날짜 선택'),
            decoration: const InputDecoration(isDense: true),
            items: List.generate(
              31,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1}일'),
              ),
            ),
            onChanged: (v) {
              if (v != null) notifier.setMonthDay(v);
            },
          ),
        ],
      ),
    );
  }
}

class _EndDateRow extends StatelessWidget {
  const _EndDateRow({
    required this.state,
    required this.notifier,
  });

  final RecurrenceSettingsState state;
  final RecurrenceSettingsController notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Row(
        children: [
          Text('종료일 (선택)', style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          if (state.endDate != null)
            TextButton(
              onPressed: () => notifier.setEndDate(null),
              child: Text(
                state.endDate!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  notifier.setEndDate(DateFormat('yyyy-MM-dd').format(picked));
                }
              },
              child: const Text('날짜 선택'),
            ),
        ],
      ),
    );
  }
}

class _PreviewDates extends StatelessWidget {
  const _PreviewDates({required this.notifier});

  final RecurrenceSettingsController notifier;

  @override
  Widget build(BuildContext context) {
    final dates = notifier.previewDates();
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
        child: Text(
          '요일 또는 날짜를 선택하면 미리보기가 표시됩니다',
          style: TextStyle(color: mutedColor),
        ),
      );
    }

    final fmt = DateFormat('yyyy년 M월 d일 (E)', 'ko');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('예정 일정', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: MinglitSpacing.xsmall),
          ...dates.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.event, size: 16, color: mutedColor),
                  const SizedBox(width: MinglitSpacing.xsmall),
                  Text(fmt.format(d)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
