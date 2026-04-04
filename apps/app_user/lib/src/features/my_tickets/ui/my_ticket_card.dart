import 'package:app_user/src/common/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #640: MyTicketCard — ticket card widget with D-Day chip, thumbnail,
/// event info, StatusBadge, and QR button.
class MyTicketCard extends StatelessWidget {
  const MyTicketCard({
    required this.application,
    required this.isPast,
    this.onTap,
    // Fix #852: onQRTap callback — replaces direct TicketQRScreen import
    this.onQRTap,
    @visibleForTesting this.currentTime,
    super.key,
  });

  final EventApplication application;
  final bool isPast;
  final VoidCallback? onTap;

  /// Callback for the QR button tap.
  final VoidCallback? onQRTap;

  /// Override current time for D-day calculation (testing only).
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = application.event;
    final ticket = application.ticket;
    final location = event?.location ?? event?.party?.location;

    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
          vertical: MinglitSpacing.xsmall2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitSpacing.medium),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MinglitSpacing.medium),
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: D-Day chip + StatusBadge
                _buildHeader(context),
                const SizedBox(height: MinglitSpacing.sm),

                // Event info row: thumbnail + text
                _buildEventInfoRow(context, event, location),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MinglitSpacing.sm,
                  ),
                  child: Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),

                // Footer: ticket name + QR button
                _buildFooter(context, ticket),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _DDayChip(
          startTime: application.event?.startTime,
          isPast: isPast,
          currentTime: currentTime,
        ),
        StatusBadge(status: application.status),
      ],
    );
  }

  Widget _buildEventInfoRow(
    BuildContext context,
    Event? event,
    Location? location,
  ) {
    final theme = Theme.of(context);
    final dateLabel = event != null
        ? DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(event.startTime)
        : '-';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail 80x80
        ClipRRect(
          borderRadius: BorderRadius.circular(MinglitSpacing.small),
          child: SizedBox(
            width: 80,
            height: 80,
            child: event?.imageUrl != null
                ? MinglitImage(
                    path: event!.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.event,
                      size: 28,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: MinglitSpacing.medium),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event name
              Text(
                event?.title ?? event?.party?.title ?? '-',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: MinglitSpacing.xsmall),

              // Date/time
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // Location
              if (location != null) ...[
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  location.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, Ticket? ticket) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Ticket name
        Expanded(
          child: Text(
            ticket?.name ?? '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // QR button (only for upcoming events)
        if (!isPast)
          TextButton.icon(
            onPressed: onQRTap,
            icon: const Icon(Icons.qr_code_2, size: 18),
            label: const Text('입장 QR'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.08,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.sm,
                vertical: MinglitSpacing.xsmall2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MinglitSpacing.small),
              ),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// D-Day chip showing remaining days or "종료".
class _DDayChip extends StatelessWidget {
  const _DDayChip({
    required this.startTime,
    required this.isPast,
    this.currentTime,
  });

  final DateTime? startTime;
  final bool isPast;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (startTime == null) {
      return const SizedBox.shrink();
    }

    final now = currentTime ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      startTime!.year,
      startTime!.month,
      startTime!.day,
    );
    final difference = eventDay.difference(todayStart).inDays;

    final String label;
    final Color bgColor;
    final Color textColor;

    if (isPast) {
      label = '종료';
      bgColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant;
    } else if (difference == 0) {
      label = 'D-Day';
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else {
      label = 'D-$difference';
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small + 2,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
        border: isPast
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
