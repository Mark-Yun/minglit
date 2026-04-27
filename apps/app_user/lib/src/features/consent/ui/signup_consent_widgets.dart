part of 'signup_consent_page.dart';

/// Fix #966: "전체 동의" 섹션 — 원형 체크박스 + primary tint 배경.
/// SwitchListTile의 switch 위젯이 디자인 언어와 맞지 않아 circular checkbox로 교체.
class _AllConsentTile extends StatelessWidget {
  const _AllConsentTile({required this.allSelected, required this.onToggle});

  final bool allSelected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTint = theme.colorScheme.primary.withValues(
      alpha: MinglitOpacity.softTint,
    );

    return Material(
      color: primaryTint,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        onTap: () => onToggle(!allSelected),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.small,
          ),
          child: Row(
            children: [
              // Fix: IgnorePointer prevents Checkbox from consuming tap events.
              // Without this, tapping the Checkbox fires both Checkbox.onChanged
              // and InkWell.onTap, flipping the toggle twice (net no-op).
              IgnorePointer(
                child: Checkbox(
                  value: allSelected,
                  shape: const CircleBorder(),
                  onChanged: (_) {},
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: MinglitSpacing.xsmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 동의',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '필수와 선택 약관을 한 번에 설정할 수 있어요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentItemTile extends StatelessWidget {
  const _ConsentItemTile({
    required this.definition,
    required this.selected,
    required this.onChanged,
    this.onShowDetail,
  });

  final _ConsentDefinition definition;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onShowDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!selected),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.small,
          ),
          child: Row(
            children: [
              // Fix: IgnorePointer prevents double-toggle (InkWell + Checkbox both firing)
              IgnorePointer(
                child: Checkbox(
                  value: selected,
                  onChanged: (_) {},
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ConsentTag(required: definition.required),
                        const SizedBox(width: MinglitSpacing.xsmall),
                        Expanded(
                          child: Text(
                            definition.title,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fix #966: TextButton('보기') → 인라인 '보기 ›' 텍스트
              if (onShowDetail != null) ...[
                const SizedBox(width: MinglitSpacing.xsmall),
                Semantics(
                  button: true,
                  label: '${definition.title} 상세 보기',
                  child: GestureDetector(
                    onTap: onShowDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.xsmall),
                      child: Text(
                        '보기 ›',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTag extends StatelessWidget {
  const _ConsentTag({required this.required});

  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = required
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final background = required
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.xsmall,
          vertical: 4,
        ),
        child: Text(
          required ? '필수' : '선택',
          style: theme.textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
