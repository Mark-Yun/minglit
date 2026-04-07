import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Screen for managing a party's recurrence rule.
///
/// Shows the current rule status (active/paused/cancelled) and provides
/// pause/resume/cancel actions.
class RecurrenceManagementScreen extends ConsumerWidget {
  const RecurrenceManagementScreen({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleAsync = ref.watch(partyRecurrenceRuleProvider(partyId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '반복 규칙 관리'),
      body: MinglitAsyncValueWidget(
        value: ruleAsync,
        data: (rule) {
          if (rule == null) {
            return const Center(child: Text('설정된 반복 규칙이 없습니다.'));
          }
          return _RecurrenceRuleContent(partyId: partyId, rule: rule);
        },
      ),
    );
  }
}

class _RecurrenceRuleContent extends ConsumerWidget {
  const _RecurrenceRuleContent({required this.partyId, required this.rule});

  final String partyId;
  final RecurrenceRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(recurrenceManagementControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChip(context, rule.status),
                const SizedBox(height: MinglitSpacing.large),
                _buildInfoCard(context, rule),
                if (rule.status == RecurrenceStatus.cancelled) ...[
                  const SizedBox(height: MinglitSpacing.large),
                  Text(
                    '취소된 규칙은 재활성화할 수 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (rule.status != RecurrenceStatus.cancelled)
          _buildActionBar(context, ref, rule, controllerState),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, RecurrenceStatus status) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      RecurrenceStatus.active => ('활성', theme.colorScheme.primary),
      RecurrenceStatus.paused => ('일시 정지', theme.colorScheme.tertiary),
      RecurrenceStatus.cancelled => ('취소됨', theme.colorScheme.error),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }

  Widget _buildInfoCard(BuildContext context, RecurrenceRule rule) {
    final theme = Theme.of(context);
    final patternLabel = switch (rule.pattern) {
      RecurrencePattern.weekly => '매주',
      RecurrencePattern.biweekly => '2주마다',
      RecurrencePattern.monthly => '매월',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '규칙 정보',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            _buildInfoRow(context, '반복 패턴', patternLabel),
            _buildInfoRow(context, '시작 시간', rule.startTime),
            _buildInfoRow(context, '종료 시간', rule.endTime),
            if (rule.endDate != null)
              _buildInfoRow(context, '종료 날짜', rule.endDate!),
            if (rule.lastGeneratedDate != null)
              _buildInfoRow(context, '마지막 생성일', rule.lastGeneratedDate!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    RecurrenceRule rule,
    AsyncValue<void> controllerState,
  ) {
    final isLoading = controllerState.isLoading;

    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: SafeArea(
        child: Row(
          children: [
            if (rule.status == RecurrenceStatus.active) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => _handlePause(context, ref, rule.id),
                  child: const Text('일시 정지'),
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => _handleCancel(context, ref, rule.id),
                  child: const Text('규칙 취소'),
                ),
              ),
            ] else if (rule.status == RecurrenceStatus.paused) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleCancel(context, ref, rule.id),
                  child: const Text('규칙 취소'),
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleResume(context, ref, rule.id),
                  child: const Text('재개'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePause(
    BuildContext context,
    WidgetRef ref,
    String ruleId,
  ) async {
    await ref
        .read(recurrenceManagementControllerProvider.notifier)
        .pause(ruleId);
    if (!context.mounted) return;
    _handleResult(context, ref, '반복 규칙이 일시 정지되었습니다.');
  }

  Future<void> _handleResume(
    BuildContext context,
    WidgetRef ref,
    String ruleId,
  ) async {
    await ref
        .read(recurrenceManagementControllerProvider.notifier)
        .resume(ruleId);
    if (!context.mounted) return;
    _handleResult(context, ref, '반복 규칙이 재개되었습니다.');
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    String ruleId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('반복 규칙 취소'),
        content: const Text('반복 규칙을 취소하면 되돌릴 수 없습니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref
        .read(recurrenceManagementControllerProvider.notifier)
        .cancel(ruleId);
    if (!context.mounted) return;
    _handleResult(context, ref, '반복 규칙이 취소되었습니다.');
  }

  void _handleResult(
    BuildContext context,
    WidgetRef ref,
    String successMessage,
  ) {
    final state = ref.read(recurrenceManagementControllerProvider);
    if (!state.hasError && context.mounted) {
      context.showMinglitSuccess(successMessage);
      ref.invalidate(partyRecurrenceRuleProvider(partyId));
    } else if (state.hasError && context.mounted) {
      handleMinglitError(context, state.error!, state.stackTrace);
    }
  }
}
