part of 'boarding_pass_card.dart';

// ---------------------------------------------------------------------------
// Section 1: Header Strip
// ---------------------------------------------------------------------------

/// Brand header strip — omagio of airline top bar.
/// Gradient background, Minglit logo (white) on left, "BOARDING PASS" on right.
class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MinglitColors.primary, MinglitColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.large,
      ),
      child: Row(
        children: [
          // White logo — ColorFiltered wraps the themed SVG
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              MinglitColors.background,
              BlendMode.srcIn,
            ),
            child: MinglitTheme.appBarLogo(height: 24),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'BOARDING PASS',
                style: TextStyle(
                  color: MinglitColors.background,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '입장권',
                style: TextStyle(
                  color: MinglitColors.background.withValues(
                    alpha: MinglitOpacity.scrimDark,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Event Info
// ---------------------------------------------------------------------------

/// Event info section — omagio of airline FROM/TO flight info zone.
/// DATE (left) → arrow → VENUE (right), then event title and ticket type.
class _EventInfoSection extends StatelessWidget {
  const _EventInfoSection({this.eventMeta});

  final TicketEventMeta? eventMeta;

  @override
  Widget build(BuildContext context) {
    final meta = eventMeta;
    final dateLabel = meta != null
        ? DateFormat('M월 d일 (E)', 'ko_KR').format(meta.eventDateTime)
        : '—';
    final timeLabel = meta != null
        ? DateFormat('HH:mm').format(meta.eventDateTime)
        : '—';
    final venueLabel = meta?.eventVenue ?? '—';
    final eventTitle = meta?.eventTitle ?? '—';
    final ticketName = meta?.ticketName;

    return Container(
      color: MinglitColors.background,
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.large,
        MinglitSpacing.medium,
        MinglitSpacing.large,
        MinglitSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flight-style info row: DATE → VENUE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: DATE section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('DATE'),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: MinglitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: MinglitColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Center: arrow aligned to time row
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  '→',
                  style: TextStyle(
                    color: MinglitColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ),
              // Right: VENUE section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const _FieldLabel('VENUE', rightAligned: true),
                    const SizedBox(height: 2),
                    Text(
                      venueLabel,
                      style: const TextStyle(
                        color: MinglitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          // Fix #1931: use theme-aware color so divider renders correctly in dark mode
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.sm),
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),

          // Event title (center aligned, 2-line ellipsis)
          Text(
            eventTitle,
            style: const TextStyle(
              color: MinglitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Ticket type (optional)
          if (ticketName != null) ...[
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              'TICKET · $ticketName',
              style: const TextStyle(
                color: MinglitColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.rightAligned = false});

  final String text;
  final bool rightAligned;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: MinglitColors.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      textAlign: rightAligned ? TextAlign.right : TextAlign.left,
    );
  }
}
