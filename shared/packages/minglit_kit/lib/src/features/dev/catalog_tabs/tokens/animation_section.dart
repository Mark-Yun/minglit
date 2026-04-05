import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all animation duration tokens.
class AnimationSection extends StatefulWidget {
  /// Creates an [AnimationSection].
  const AnimationSection({super.key});

  @override
  State<AnimationSection> createState() => _AnimationSectionState();
}

class _AnimationSectionState extends State<AnimationSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetWidth = _expanded ? 200.0 : 80.0;

    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Animation Durations', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap the button to toggle animated containers.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        ElevatedButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Collapse' : 'Expand'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        _AnimationRow(
          label: 'fast (200ms)',
          duration: MinglitAnimation.fast,
          targetWidth: targetWidth,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        _AnimationRow(
          label: 'medium (350ms)',
          duration: MinglitAnimation.medium,
          targetWidth: targetWidth,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        _AnimationRow(
          label: 'slow (500ms)',
          duration: MinglitAnimation.slow,
          targetWidth: targetWidth,
        ),
      ],
    );
  }
}

class _AnimationRow extends StatelessWidget {
  const _AnimationRow({
    required this.label,
    required this.duration,
    required this.targetWidth,
  });

  final String label;
  final Duration duration;
  final double targetWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          width: targetWidth,
          height: 40,
          decoration: BoxDecoration(
            color: MinglitColors.primary.withAlpha(180),
            borderRadius: BorderRadius.circular(MinglitRadius.small),
          ),
        ),
      ],
    );
  }
}
