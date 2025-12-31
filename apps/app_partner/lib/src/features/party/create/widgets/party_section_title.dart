import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartySectionTitle extends StatelessWidget {
  const PartySectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary, // Midnight Navy
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
