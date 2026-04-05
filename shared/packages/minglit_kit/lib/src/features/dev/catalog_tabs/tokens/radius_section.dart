import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all border radius tokens.
class RadiusSection extends StatelessWidget {
  /// Creates a [RadiusSection].
  const RadiusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radii = <String, double>{
      'small (8)': MinglitRadius.small,
      'input (12)': MinglitRadius.input,
      'button (16)': MinglitRadius.button,
      'card (24)': MinglitRadius.card,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: radii.length,
      itemBuilder: (context, index) {
        final entry = radii.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MinglitColors.primary.withAlpha(30),
                  border: Border.all(color: MinglitColors.primary),
                  borderRadius: BorderRadius.circular(entry.value),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.value.toInt()}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
