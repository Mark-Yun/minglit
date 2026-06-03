import 'package:app_partner/src/logic/event_operation_phase.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeUpcomingEventCard extends StatelessWidget {
  const HomeUpcomingEventCard({
    required this.event,
    required this.onTap,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = getEventPhase(event);
    final isCheckinReady = phase == EventPhase.checkinReady;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined),
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: Text(
                    event.title ?? '이벤트 준비 중',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              isCheckinReady ? '체크인 가능' : '체크인 대기',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              width: double.infinity,
              child: isCheckinReady
                  ? MinglitButton(
                      label: '참가자 체크인',
                      icon: Icons.qr_code_scanner,
                      onPressed: onTap,
                    )
                  : OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('참가자 리스트'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
