import 'package:app_user/src/common/event_ticket_token_provider.dart';
import 'package:app_user/src/common/widgets/ticket_qr_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Phase 1: Check-in Ready — QR code + event info + location link
// ---------------------------------------------------------------------------

class CheckInReadyContent extends ConsumerWidget {
  const CheckInReadyContent({required this.activeEvent, super.key});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final ticketTokenAsync = ref.watch(
      eventTicketTokenProvider(event.id),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Event name
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.small),

          // Event time
          Text(
            _formatEventTime(event),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // QR Code
          ticketTokenAsync.when(
            data: (token) {
              if (token == null) {
                return _QRErrorWidget(eventId: event.id);
              }
              return TicketQRViewer(token: token);
            },
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: MinglitCircularProgressIndicator()),
            ),
            error: (_, _) => _QRErrorWidget(eventId: event.id),
          ),

          const SizedBox(height: MinglitSpacing.large),

          // Location info + deeplink
          if (event.party?.location != null) ...[
            _LocationRow(location: event.party!.location!),
            const SizedBox(height: MinglitSpacing.medium),
          ],
        ],
      ),
    );
  }

  String _formatEventTime(Event event) {
    final dateFormat = DateFormat('M월 d일 HH:mm');
    return dateFormat.format(event.startTime);
  }
}

/// QR load failure widget with retry button.
class _QRErrorWidget extends ConsumerWidget {
  const _QRErrorWidget({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: MinglitColors.error,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            'QR 코드를 불러올 수 없습니다',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextButton.icon(
            onPressed: () => ref.invalidate(eventTicketTokenProvider(eventId)),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

/// Location row with name + "위치 안내 보기" button.
class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openLocationDeeplink(context),
      borderRadius: BorderRadius.circular(MinglitRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MinglitSpacing.small,
          horizontal: MinglitSpacing.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: MinglitColors.primary,
              size: MinglitIconSize.small,
            ),
            const SizedBox(width: MinglitSpacing.small),
            Flexible(
              child: Text(
                location.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            Text(
              '위치 안내 보기',
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationDeeplink(BuildContext context) async {
    // Fix #663: Use geo: URI scheme for cross-platform map deeplink
    final uri = Uri.parse(
      'geo:${location.latitude},${location.longitude}'
      '?q=${Uri.encodeComponent(location.address)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도 앱을 열 수 없습니다')),
        );
      }
    }
  }
}
