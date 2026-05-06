import 'dart:async';

import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class EventOngoingBanner extends StatelessWidget {
  const EventOngoingBanner({
    required this.application,
    required this.phase,
    required this.onMarkResultsViewed,
    super.key,
  });

  final EventApplication application;
  final EventLifecyclePhase phase;
  final VoidCallback onMarkResultsViewed;

  @override
  Widget build(BuildContext context) {
    final event = application.event;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final location = event?.location ?? event?.party?.location;
    const imageSize = MinglitSpacing.xlarge + MinglitSpacing.large;
    final footer = _buildFooter(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.xsmall2,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PhaseChip(phase: phase),
                const Spacer(),
                Text(
                  event == null
                      ? '-'
                      : DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(
                          event.startTime,
                        ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(MinglitRadius.small),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: event?.imageUrl != null
                        ? MinglitImage(
                            path: event!.imageUrl!,
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.event_outlined,
                              size: MinglitIconSize.medium,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event?.title ?? event?.party?.title ?? '이벤트',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Text(
                        location?.name ?? '장소 미정',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: MinglitSpacing.medium),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFooter(BuildContext context) {
    return switch (phase) {
      EventLifecyclePhase.waiting => Wrap(
        spacing: MinglitSpacing.small,
        runSpacing: MinglitSpacing.small,
        children: [
          OutlinedButton(
            onPressed: () => _openQr(context),
            child: const Text('입장 QR 미리 보기'),
          ),
          OutlinedButton(
            onPressed: () => _openDirections(context),
            child: const Text('길찾기'),
          ),
        ],
      ),
      EventLifecyclePhase.checkInReady => Wrap(
        spacing: MinglitSpacing.small,
        runSpacing: MinglitSpacing.small,
        children: [
          FilledButton(
            onPressed: () => _openQr(context),
            child: const Text('입장 QR 보기'),
          ),
          OutlinedButton(
            onPressed: () => _openDirections(context),
            child: const Text('길찾기'),
          ),
        ],
      ),
      EventLifecyclePhase.checkedIn => null,
      EventLifecyclePhase.matchingReady => FilledButton(
        onPressed: () => _openMatching(context),
        child: const Text('매칭 시작하기'),
      ),
      EventLifecyclePhase.matching => Text(
        '매칭 결과를 기다리고 있습니다',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      EventLifecyclePhase.resultsUnviewed => FilledButton(
        onPressed: () {
          onMarkResultsViewed();
          _openMatching(context);
        },
        child: const Text('매칭 결과 보기'),
      ),
      EventLifecyclePhase.resultsViewed => OutlinedButton(
        onPressed: () => _openMatching(context),
        child: const Text('매칭 결과 다시 보기'),
      ),
      EventLifecyclePhase.noShow => null,
      EventLifecyclePhase.ended => null,
    };
  }

  void _openQr(BuildContext context) {
    unawaited(
      TicketQRRoute(
        ticketId: application.ticketId,
        $extra: _buildTicketEventMeta(),
      ).push<void>(context),
    );
  }

  void _openMatching(BuildContext context) {
    unawaited(
      EventMatchingRoute(eventId: application.eventId).push<void>(context),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final location =
        application.event?.location ?? application.event?.party?.location;
    if (location == null) return;

    final uri = Uri.parse(
      'geo:${location.latitude},${location.longitude}'
      '?q=${Uri.encodeComponent(location.address)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('지도 앱을 열 수 없습니다')));
      }
    }
  }

  TicketEventMeta? _buildTicketEventMeta() {
    final event = application.event;
    final title = event?.title ?? event?.party?.title;
    if (event == null || title == null) return null;

    return TicketEventMeta(
      eventTitle: title,
      eventDateTime: event.startTime,
      eventVenue: event.location?.name ?? event.party?.location?.name,
      ticketName: application.ticket?.name,
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase});

  final EventLifecyclePhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = switch (phase) {
      EventLifecyclePhase.waiting => theme.colorScheme.tertiary,
      EventLifecyclePhase.noShow => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.primary,
    };
    final foregroundColor = switch (phase) {
      EventLifecyclePhase.waiting => theme.colorScheme.onTertiary,
      EventLifecyclePhase.noShow => theme.colorScheme.surface,
      _ => theme.colorScheme.onPrimary,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        child: Text(
          _phaseLabel(phase),
          style: theme.textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _phaseLabel(EventLifecyclePhase phase) {
    return switch (phase) {
      EventLifecyclePhase.waiting => '입장 대기',
      EventLifecyclePhase.checkInReady => '입장 가능',
      EventLifecyclePhase.checkedIn => '체크인 완료',
      EventLifecyclePhase.matchingReady => '매칭 준비',
      EventLifecyclePhase.matching => '매칭 진행 중',
      EventLifecyclePhase.resultsUnviewed => '결과 확인 필요',
      EventLifecyclePhase.resultsViewed => '결과 확인 완료',
      EventLifecyclePhase.noShow => '노쇼',
      EventLifecyclePhase.ended => '종료',
    };
  }
}
