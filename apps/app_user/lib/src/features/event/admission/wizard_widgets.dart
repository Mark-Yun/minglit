part of 'event_application_wizard_page.dart';

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.steps, required this.currentStep});

  final List<EventApplicationStep> steps;
  final EventApplicationStep currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = steps.indexOf(currentStep);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _buildCircle(
              context,
              index: index,
              label: _labelFor(steps[index]),
              isDone: index < currentIndex,
              isActive: index == currentIndex,
            ),
            if (index < steps.length - 1)
              Container(
                width: MinglitSpacing.xlarge,
                height: MinglitSpacing.xxsmall,
                margin: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.small,
                ),
                color: index < currentIndex
                    ? MinglitColors.success
                    : theme.colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }

  String _labelFor(EventApplicationStep step) {
    return switch (step) {
      EventApplicationStep.identity => '본인인증',
      EventApplicationStep.partnerVerification => '추가인증',
      EventApplicationStep.consent => '동의',
      EventApplicationStep.payment => '결제',
    };
  }

  Widget _buildCircle(
    BuildContext context, {
    required int index,
    required String label,
    required bool isDone,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final color = isDone
        ? MinglitColors.success
        : isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final textColor = isDone || isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: MinglitSpacing.xlarge,
          height: MinglitSpacing.xlarge,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          alignment: Alignment.center,
          child: isDone
              ? Icon(
                  Icons.check,
                  size: MinglitIconSize.small,
                  color: theme.colorScheme.onPrimary,
                )
              : Text(
                  '${index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive || isDone
                ? color
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.steps,
    required this.canMoveNext,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  final EventApplicationState state;
  final List<EventApplicationStep> steps;
  final bool canMoveNext;
  final VoidCallback onPrev;
  final Future<void> Function() onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstStep = steps.first == state.step;
    final isLastStep = steps.last == state.step;
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
                child: MinglitButton.secondary(
                  label: '이전',
                  onPressed: isSubmitting ? null : onPrev,
                  isLoading: isSubmitting,
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
            ],
            Expanded(
              flex: 2,
              child: MinglitButton(
                label: isLastStep ? '결제하기' : '다음',
                onPressed: isSubmitting
                    ? null
                    : isLastStep
                    ? onSubmit
                    : canMoveNext
                    ? () {
                        unawaited(onNext());
                      }
                    : null,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
