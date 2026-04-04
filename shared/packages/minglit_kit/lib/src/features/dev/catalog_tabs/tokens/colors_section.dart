import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all color tokens.
class ColorsSection extends StatelessWidget {
  /// Creates a [ColorsSection].
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Light Colors', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            _ColorChip('background', MinglitColors.background),
            _ColorChip('primary', MinglitColors.primary),
            _ColorChip('secondary', MinglitColors.secondary),
            _ColorChip('tertiary', MinglitColors.tertiary),
            _ColorChip('surface', MinglitColors.surface),
            _ColorChip('error', MinglitColors.error),
            _ColorChip('textPrimary', MinglitColors.textPrimary),
            _ColorChip('textSecondary', MinglitColors.textSecondary),
            _ColorChip('success', MinglitColors.success),
            _ColorChip('warning', MinglitColors.warning),
            _ColorChip('transparent', MinglitColors.transparent),
            _ColorChip('scrim', MinglitColors.scrim),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Dark Colors', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: MinglitColorsDark.background,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: const Wrap(
            spacing: MinglitSpacing.small,
            runSpacing: MinglitSpacing.small,
            children: [
              _ColorChip(
                'background',
                MinglitColorsDark.background,
                darkBg: true,
              ),
              _ColorChip('surface', MinglitColorsDark.surface, darkBg: true),
              _ColorChip(
                'textPrimary',
                MinglitColorsDark.textPrimary,
                darkBg: true,
              ),
              _ColorChip(
                'textSecondary',
                MinglitColorsDark.textSecondary,
                darkBg: true,
              ),
              _ColorChip('primary', MinglitColorsDark.primary, darkBg: true),
              _ColorChip(
                'secondary',
                MinglitColorsDark.secondary,
                darkBg: true,
              ),
              _ColorChip('tertiary', MinglitColorsDark.tertiary, darkBg: true),
              _ColorChip('error', MinglitColorsDark.error, darkBg: true),
              _ColorChip('divider', MinglitColorsDark.divider, darkBg: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(this.name, this.color, {this.darkBg = false});

  final String name;
  final Color color;
  final bool darkBg;

  @override
  Widget build(BuildContext context) {
    final hex =
        // ignore: deprecated_member_use -- Color.value is still the simplest hex conversion
        '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final labelColor = darkBg ? MinglitColorsDark.textPrimary : null;
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
              border: Border.all(
                color: darkBg
                    ? MinglitColorsDark.divider
                    : MinglitColors.textSecondary.withAlpha(50),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hex,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: labelColor ?? MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
