import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeLiveEventCard extends StatelessWidget {
  const HomeLiveEventCard({
    required this.event,
    required this.onCheckin,
    super.key,
  });

  final Event event;
  final VoidCallback onCheckin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: MinglitColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: Text(
                event.title ?? '진행 중인 이벤트',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            MinglitButton(
              label: '체크인',
              size: MinglitButtonSize.small,
              expand: false,
              onPressed: onCheckin,
            ),
          ],
        ),
      ),
    );
  }
}
