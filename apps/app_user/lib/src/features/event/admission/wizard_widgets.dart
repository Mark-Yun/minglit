part of 'event_application_wizard_page.dart';

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final EventApplicationStep currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircle(
            context,
            '1',
            '인증',
            currentStep == EventApplicationStep.verification,
          ),
          Container(
            width: MinglitSpacing.xlarge + MinglitSpacing.small, // 40
            height: 2,
            color: theme.colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
            ),
          ),
          _buildCircle(
            context,
            '2',
            '결제',
            currentStep == EventApplicationStep.payment,
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(
    BuildContext context,
    String num,
    String label,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    final color =
        isActive ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Column(
      children: [
        CircleAvatar(
          radius: MinglitSpacing
              .medium, // Changed from 12 to 16 for better alignment with tokens
          backgroundColor: color,
          child: Text(
            num,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  final EventApplicationState state;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstStep = state.step == EventApplicationStep.verification;
    final isSubmitting = state.status == EventApplicationStatus.submitting;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onPrev,
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    isSubmitting ? null : (isFirstStep ? onNext : onSubmit),
                child: isSubmitting
                    ? const MinglitCircularProgressIndicator(
                        size: 20,
                      )
                    : Text(isFirstStep ? '다음' : '결제하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
