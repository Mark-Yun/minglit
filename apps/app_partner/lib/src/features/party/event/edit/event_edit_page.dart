import 'package:app_partner/src/features/party/event/edit/event_edit_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventEditPage extends ConsumerWidget {
  const EventEditPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(eventEditControllerProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('이벤트 수정'),
      ),
      body: MinglitAsyncValueWidget<EventEditState>(
        value: stateAsync,
        data: (editState) => _EventEditContent(
          eventId: eventId,
          editState: editState,
        ),
      ),
      bottomNavigationBar: stateAsync.whenOrNull(
        data: (editState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !editState.isDirty || editState.isLoading
                    ? null
                    : () async {
                        // Fix #2110: collect reason when confirmed participants ≥1
                        // and schedule changed — spec §Lock Policy requires it.
                        String? reason;
                        if (editState.confirmedCount >= 1 &&
                            editState.isScheduleChanged) {
                          if (!context.mounted) return;
                          reason = await _showReasonDialog(context);
                          if (reason == null) return; // User cancelled.
                        }

                        // Fix #2110: catch submit errors to prevent uncaught
                        // async exception (debug red screen / release silent crash).
                        // Capture messenger before pop — context is disposed after pop.
                        try {
                          await ref
                              .read(
                                eventEditControllerProvider(eventId).notifier,
                              )
                              .submit(reason: reason);
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          context.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('저장되었습니다')),
                          );
                        } on Exception catch (_) {
                          if (!context.mounted) return;
                          context.showMinglitWarning(
                            '저장에 실패했습니다. 다시 시도해주세요.',
                          );
                        }
                      },
                child: Text(editState.isLoading ? '저장 중...' : '저장'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fix #2110: spec §Lock Policy — schedule change with confirmed participants ≥1
// must collect a reason. Notifications are sent server-side (via EF).
Future<String?> _showReasonDialog(BuildContext context) async {
  String? reason;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('일정 변경 사유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('확정 참가자에게 일정 변경 알림이 전송됩니다. 변경 사유를 입력해주세요.'),
            const SizedBox(height: MinglitSpacing.medium),
            TextField(
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '변경 사유 입력 (예: 장소 이전 불가로 인한 날짜 변경)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => reason = value.trim(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = reason?.trim();
              if (trimmed == null || trimmed.isEmpty) return;
              Navigator.of(dialogContext).pop(trimmed);
            },
            child: const Text('저장 및 알림 전송'),
          ),
        ],
      );
    },
  );
}

class _EventEditContent extends ConsumerWidget {
  const _EventEditContent({required this.eventId, required this.editState});

  final String eventId;
  final EventEditState editState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(eventEditControllerProvider(eventId).notifier);
    final colorScheme = theme.colorScheme;
    final hasConfirmedParticipants = editState.confirmedCount >= 1;
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
    final timeFormat = DateFormat('a h:mm', 'ko');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasConfirmedParticipants) ...[
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: colorScheme.primary,
                    size: MinglitIconSize.small,
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  // Fix #2110: spec §Lock Policy — two-level typography:
                  // title (labelLarge) + sub (bodySmall). Sub must list all
                  // three constraints: alert, min-capacity, price policy.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '확정 참가자 ${editState.confirmedCount}명',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '일정·장소 변경 시 자동 알림 발송. '
                          '정원은 확정자 수 이하로 줄일 수 없음.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
          ],
          Text('기본 정보', style: theme.textTheme.titleMedium),
          const SizedBox(height: MinglitSpacing.small),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('제목', style: theme.textTheme.labelLarge),
                const SizedBox(height: MinglitSpacing.xsmall),
                TextFormField(
                  initialValue: editState.title,
                  onChanged: controller.updateTitle,
                  decoration: const InputDecoration(hintText: '이벤트 제목'),
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text('일정·장소', style: theme.textTheme.titleMedium),
          const SizedBox(height: MinglitSpacing.small),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('일정', style: theme.textTheme.labelLarge),
                          const SizedBox(height: MinglitSpacing.xsmall),
                          Text(
                            dateFormat.format(editState.startTime),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: MinglitSpacing.xxsmall),
                          Text(
                            '${timeFormat.format(editState.startTime)} '
                            '~ ${timeFormat.format(editState.endTime)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MinglitSpacing.small),
                    if (hasConfirmedParticipants)
                      Chip(
                        label: Text(
                          '변경 시 알림',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    IconButton(
                      onPressed: () => _pickSchedule(
                        context: context,
                        state: editState,
                        onApply: controller.updateSchedule,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Text('장소', style: theme.textTheme.labelLarge),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  editState.location ?? '장소 미정',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text('가격·정원', style: theme.textTheme.titleMedium),
          const SizedBox(height: MinglitSpacing.small),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최대 인원', style: theme.textTheme.labelLarge),
                const SizedBox(height: MinglitSpacing.xsmall),
                TextFormField(
                  initialValue: editState.maxParticipants.toString(),
                  keyboardType: TextInputType.number,
                  // Fix #2110: prevent empty/non-digit input — ensures field
                  // value always reflects controller state (no ghost values).
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed == null) return;
                    controller.updateMaxParticipants(parsed);
                  },
                  decoration: InputDecoration(
                    hintText: hasConfirmedParticipants
                        ? '최소 ${editState.confirmedCount}명'
                        : '최소 1명',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSchedule({
    required BuildContext context,
    required EventEditState state,
    required void Function({
      required DateTime startTime,
      required DateTime endTime,
      required String? location,
    })
    onApply,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: state.startTime,
      firstDate: state.startTime.subtract(const Duration(days: 365)),
      lastDate: state.startTime.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.startTime),
    );
    if (pickedStart == null || !context.mounted) return;

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.endTime),
    );
    if (pickedEnd == null || !context.mounted) return;

    final startTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedStart.hour,
      pickedStart.minute,
    );
    final endTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedEnd.hour,
      pickedEnd.minute,
    );

    onApply(
      startTime: startTime,
      endTime: endTime,
      location: state.location,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: child,
    );
  }
}
