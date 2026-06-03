import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:app_partner/src/logic/event_operation_phase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class OngoingEventListPage extends StatelessWidget {
  const OngoingEventListPage({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    if (isCheckinActionEnabled(event)) {
      return Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: MinglitPartnerColors.primary,
            brightness: Brightness.dark,
          ),
        ),
        child: QRScannerScreen(event: event),
      );
    }

    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm');
    final checkinStart = event.startTime.subtract(const Duration(hours: 2));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '참가자 리스트'),
      body: ListView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        children: [
          Text(
            event.title ?? event.party?.title ?? '이벤트',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            '${timeFmt.format(event.startTime)} 시작 · '
            '체크인 ${timeFmt.format(checkinStart)}부터',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          _ReadinessSummary(event: event),
          const SizedBox(height: MinglitSpacing.medium),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Text(
                      'T-2 전에는 QR/수동 체크인이 비활성화됩니다. 명단과 참가 현황을 미리 확인해 주세요.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          MinglitButton(
            label: '체크인은 ${timeFmt.format(checkinStart)}부터 가능',
            icon: Icons.qr_code_scanner,
          ),
        ],
      ),
    );
  }
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capacity = event.maxParticipants;
    final confirmed = event.currentParticipants;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '참가 현황',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '확정 $confirmed명 · 정원 $capacity명',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: MinglitSpacing.small),
            LinearProgressIndicator(
              value: capacity > 0 ? confirmed / capacity : 0,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}
