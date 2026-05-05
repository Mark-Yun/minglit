import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.onMoreTap,
    super.key,
  });

  final String title;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onMoreTap != null)
          TextButton(
            onPressed: onMoreTap,
            child: const Text('더보기'),
          ),
      ],
    );
  }
}
