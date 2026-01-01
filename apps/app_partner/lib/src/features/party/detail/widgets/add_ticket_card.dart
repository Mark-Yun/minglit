import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class AddTicketCard extends StatelessWidget {
  const AddTicketCard({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: MinglitAnimation.fast,
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MinglitRadius.input),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.input),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: colorScheme.tertiary,
                size: MinglitIconSize.small,
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '새로운 티켓 만들기',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      '성별/나이 제한 등 판매 조건을 설정하세요.',
                      style: MinglitTextStyles.infoText(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Icon(
                Icons.chevron_right,
                color: colorScheme.tertiary.withValues(alpha: 0.6),
                size: MinglitIconSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
