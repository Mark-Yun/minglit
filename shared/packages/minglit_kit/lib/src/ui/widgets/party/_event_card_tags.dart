part of 'event_card.dart';

/// Displays up to 3 tag chips with an overflow "+N" badge.
///
/// Used in [MinglitEventCard] to surface tag metadata
/// (Tag Discovery #1094-1096).
class _TagChipRow extends StatelessWidget {
  const _TagChipRow({required this.tags, this.onTagTap});

  static const _maxVisible = 3;

  final List<Tag> tags;
  final void Function(Tag tag)? onTagTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = tags.take(_maxVisible).toList();
    final overflowCount = tags.length - visible.length;

    return Wrap(
      spacing: MinglitSpacing.xsmall,
      runSpacing: MinglitSpacing.xxsmall,
      children: [
        for (final tag in visible)
          _TagBadge(
            label: tag.name,
            theme: theme,
            onTap: onTagTap == null ? null : () => onTagTap!(tag),
          ),
        if (overflowCount > 0)
          _TagBadge(label: '+$overflowCount', theme: theme),
      ],
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.theme,
    this.onTap,
  });

  final String label;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        child: Text(
          '#$label',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    if (onTap == null) return chip;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: chip,
    );
  }
}
