import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_filter_chip.dart';

/// Design catalog tab displaying button widgets.
class ButtonsSection extends StatefulWidget {
  /// Creates a [ButtonsSection].
  const ButtonsSection({super.key});

  @override
  State<ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<ButtonsSection> {
  bool _filterSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('ElevatedButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              const Text('Loading...'),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('OutlinedButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        OutlinedButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const OutlinedButton(onPressed: null, child: Text('Disabled')),
        const SizedBox(height: MinglitSpacing.large),
        Text('TextButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        TextButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const TextButton(onPressed: null, child: Text('Disabled')),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitChip
        Text('MinglitChip', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitChip(label: 'Default'),
            MinglitChip(label: 'With Icon', icon: Icons.flutter_dash),
            MinglitChip(
              label: 'Small',
              size: MinglitChipSize.small,
              icon: Icons.star,
            ),
            MinglitChip(
              label: 'Large',
              size: MinglitChipSize.large,
            ),
            MinglitChip(
              label: 'Colored',
              color: MinglitColors.primary,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitFilterChip
        Text('MinglitFilterChip', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitFilterChip(
              label: '최신순',
              isSelected: _filterSelected,
              icon: Icons.sort,
              onTap: () => setState(() => _filterSelected = !_filterSelected),
            ),
            MinglitFilterChip(
              label: '인기순',
              isSelected: !_filterSelected,
              onTap: () => setState(() => _filterSelected = !_filterSelected),
            ),
          ],
        ),
      ],
    );
  }
}
