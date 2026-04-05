import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying input widgets.
class InputsSection extends StatefulWidget {
  /// Creates an [InputsSection].
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // TextField demos
        Text('TextField', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Normal input field',
            labelText: 'Label',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Value', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        TextFormField(
          initialValue: 'Minglit',
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Error State', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Error input',
            labelText: 'Email',
            errorText: 'Invalid email format',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Disabled', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Disabled input field',
            labelText: 'Disabled',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Prefix & Suffix', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // Checkbox demos
        Text('Checkbox', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        CheckboxListTile(
          title: const Text('Selected'),
          value: _checked,
          onChanged: (v) => setState(() => _checked = v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Unselected'),
          value: false,
          onChanged: (v) {},
        ),
        const CheckboxListTile(
          title: Text('Disabled (selected)'),
          value: true,
          onChanged: null,
        ),
        const CheckboxListTile(
          title: Text('Disabled (unselected)'),
          value: false,
          onChanged: null,
        ),
      ],
    );
  }
}
