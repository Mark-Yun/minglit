import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    required this.currentIndex,
    required this.totalCount,
    super.key,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final isActive = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.xsmall,
          ),
          child: AnimatedContainer(
            duration: MinglitAnimation.medium,
            width: isActive ? 10.0 : 8.0,
            height: isActive ? 10.0 : 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? MinglitColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
