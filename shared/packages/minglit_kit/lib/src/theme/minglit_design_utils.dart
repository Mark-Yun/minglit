part of 'minglit_theme.dart';

class MinglitShadows {
  static List<BoxShadow> cardSelected(Color accentColor) => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.1),
      blurRadius: MinglitSpacing.small,
      offset: const Offset(0, 4),
    ),
  ];
}

class MinglitBorders {
  static Border card(ColorScheme colorScheme, {bool isSelected = false}) =>
      Border.all(
        color: isSelected ? colorScheme.secondary : colorScheme.outlineVariant,
      );
}

class MinglitDecorations {
  static BoxDecoration selectableCard(
    BuildContext context, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary;

    return BoxDecoration(
      color: isSelected ? accentColor.withValues(alpha: 0.05) : theme.cardColor,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      border: MinglitBorders.card(colorScheme, isSelected: isSelected),
      boxShadow: isSelected ? MinglitShadows.cardSelected(accentColor) : null,
    );
  }
}

class MinglitTextStyles {
  static TextStyle selectableCardTitle(
    BuildContext context, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall!.copyWith(
      color: isSelected ? theme.colorScheme.secondary : null,
    );
  }

  static TextStyle selectableCardSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: 11,
    );
  }

  static TextStyle selectableCardDescription(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle infoText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
  }
}
