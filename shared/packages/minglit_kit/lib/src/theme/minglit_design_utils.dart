part of 'minglit_theme.dart';

/// Shadow presets for Minglit UI components.
class MinglitShadows {
  /// Returns a card shadow using the given accent color.
  static List<BoxShadow> cardSelected(Color accentColor) => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.1),
      blurRadius: MinglitSpacing.small,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Border presets for Minglit UI components.
class MinglitBorders {
  /// Returns a card border, highlighted when [isSelected].
  static Border card(ColorScheme colorScheme, {bool isSelected = false}) =>
      Border.all(
        color: isSelected ? colorScheme.secondary : colorScheme.outlineVariant,
      );
}

/// Decoration presets for Minglit UI components.
class MinglitDecorations {
  /// Returns a selectable card decoration based on selection state.
  static BoxDecoration selectableCard(
    BuildContext context, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary;

    return BoxDecoration(
      color: isSelected ? accentColor.withValues(alpha: MinglitOpacity.tintFill) : theme.cardColor,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      border: MinglitBorders.card(colorScheme, isSelected: isSelected),
      boxShadow: isSelected ? MinglitShadows.cardSelected(accentColor) : null,
    );
  }
}

/// Text style presets for Minglit UI components.
class MinglitTextStyles {
  /// Returns a title style for selectable cards.
  static TextStyle selectableCardTitle(
    BuildContext context, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall!.copyWith(
      color: isSelected ? theme.colorScheme.secondary : null,
    );
  }

  /// Returns a subtitle style for selectable cards.
  // Fix #474: fontSize 11 → labelSmall (이미 11px)
  static TextStyle selectableCardSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    );
  }

  /// Returns a description style for selectable cards.
  static TextStyle selectableCardDescription(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Returns an info text style.
  // Fix #474: fontSize 12 → bodySmall (이미 12px)
  static TextStyle infoText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}
