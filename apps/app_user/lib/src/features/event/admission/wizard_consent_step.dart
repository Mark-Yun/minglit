part of 'event_application_wizard_page.dart';

class _ConsentStep extends ConsumerStatefulWidget {
  const _ConsentStep({required this.event});

  final Event event;

  @override
  ConsumerState<_ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends ConsumerState<_ConsentStep> {
  @override
  void initState() {
    super.initState();
    // Fix #2343: defer state modification to post-frame to avoid
    // "Tried to modify a provider while the widget tree was building".
    // initState is called synchronously during the parent's build phase,
    // so any state mutation must be deferred.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(eventApplicationControllerProvider(widget.event).notifier)
          .initConsentItems(_consentItems.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checked = ref.watch(
      eventApplicationControllerProvider(
        widget.event,
      ).select((s) => s.consentCheckedItems),
    );

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
            '개인정보 및 심사 동의',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '심사와 신청 처리를 위해 아래 항목에 모두 동의해주세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          if (checked.isNotEmpty)
            ...List.generate(
              _consentItems.length,
              // Fix #2346: contentPadding: zero로 인해 체크박스가 카드 내부 edge에
            // 붙어 좌표 기반 자동화의 예상 위치와 달랐음. 기본 패딩으로 복원해
            // 표준 터치 타겟 위치 확보.
            (index) => CheckboxListTile(
                value: checked[index],
                onChanged: (value) {
                  ref
                      .read(
                        eventApplicationControllerProvider(
                          widget.event,
                        ).notifier,
                      )
                      .toggleConsentItem(index, value ?? false);
                },
                title: Text(
                  _consentItems[index],
                  style: theme.textTheme.bodyMedium,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }
}

const _consentItems = <String>[
  '제출한 인증 정보가 파트너 심사에 사용되는 것에 동의합니다.',
  '이벤트 참여 심사 결과가 앱 내 신청 상태에 반영되는 것에 동의합니다.',
  '허위 정보 제출 시 신청이 취소될 수 있음을 확인했습니다.',
];
