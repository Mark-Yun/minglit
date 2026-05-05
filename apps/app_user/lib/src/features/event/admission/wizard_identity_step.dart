part of 'event_application_wizard_page.dart';

class _IdentityStep extends ConsumerWidget {
  const _IdentityStep({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(eventApplicationControllerProvider(event));

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '본인 인증',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            'PASS 본인인증은 다음 PR에서 연결됩니다. 현재는 흐름 검증을 위한 스텁 버튼만 제공합니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          SizedBox(
            width: double.infinity,
            child: MinglitButton(
              label: state.identityCompleted ? '본인인증 완료' : '본인인증하기',
              onPressed: state.identityCompleted
                  ? null
                  : ref
                        .read(
                          eventApplicationControllerProvider(event).notifier,
                        )
                        .markIdentityCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
