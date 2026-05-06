import 'package:app_partner/src/features/party/list/party_with_stats.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 4-region party card: Hero / Body / Stats / Bottom CTA.
///
/// Spec: apps/mds/docs/public/specs/party_list_page.html
class PartyListItem extends StatelessWidget {
  const PartyListItem({
    required this.entry,
    required this.onTap,
    this.onNextEventTap,
    this.onCreateEventTap,
    super.key,
  });

  final PartyWithStats entry;

  /// Tapping Hero/Body/Stats region navigates to PartyDetail.
  final VoidCallback onTap;

  /// Tapping the "다음 이벤트" row navigates to EventDetail. Null if no next event.
  final VoidCallback? onNextEventTap;

  final VoidCallback? onCreateEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = entry.party;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Region 1: Hero (2:1 image) ────────────────────────────────
            _HeroRegion(party: party),

            // ── Region 2: Body (title + location) ─────────────────────────
            // Fix #2201: spec says Hero ↔ Body has no divider
            _BodyRegion(party: party),

            // ── Inset divider ─────────────────────────────────────────────
            _InsetDivider(),

            // ── Region 3: Stats (completed / upcoming counts) ─────────────
            _StatsRegion(entry: entry),

            // ── Inset divider ─────────────────────────────────────────────
            _InsetDivider(),

            // ── Region 4: Bottom CTA ──────────────────────────────────────
            _BottomCtaRegion(
              entry: entry,
              onNextEventTap: onNextEventTap,
              onCreateEventTap: onCreateEventTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Region 1 — Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroRegion extends StatelessWidget {
  const _HeroRegion({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (party.imageUrl != null)
            Image.network(
              party.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _ImagePlaceholder(),
            )
          else
            _ImagePlaceholder(),

          // Bottom-up gradient fade
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),

          // Partner overlay (top-left)
          Positioned(
            top: MinglitSpacing.small,
            left: MinglitSpacing.small,
            child: _PartnerOverlay(party: party),
          ),

          // Tags (bottom-left of image)
          if (party.tags != null && party.tags!.isNotEmpty)
            Positioned(
              bottom: MinglitSpacing.small,
              left: MinglitSpacing.small,
              right: MinglitSpacing.small,
              child: Wrap(
                spacing: MinglitSpacing.xxsmall,
                runSpacing: MinglitSpacing.xxsmall,
                children: [
                  for (final tag in party.tags!.take(3))
                    _HeroTag(label: tag.name),
                  if (party.tags!.length > 3)
                    _HeroTag(label: '+${party.tags!.length - 3}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.celebration_outlined,
          size: MinglitIconSize.xlarge,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _PartnerOverlay extends StatelessWidget {
  const _PartnerOverlay({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final partner = party.partner;
    if (partner == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: partner.profileImageUrl != null
                ? NetworkImage(partner.profileImageUrl!)
                : null,
            child: partner.profileImageUrl == null
                ? const Icon(Icons.storefront, size: MinglitIconSize.xsmall)
                : null,
          ),
          const SizedBox(width: MinglitSpacing.xxsmall),
          Text(
            party.partner?.name ?? '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.xsmall,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Text(
        label,
        // TODO(#2274): labelSmall보다 작은 토큰 없음 — MDS 확장 대기
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.surface,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Region 2 — Body
// ─────────────────────────────────────────────────────────────────────────────

class _BodyRegion extends StatelessWidget {
  const _BodyRegion({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  party.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Fix #2201: optional draft chip per spec title-row blueprint
              if (party.status == 'draft') ...[
                const SizedBox(width: MinglitSpacing.xxsmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.xsmall,
                    vertical: MinglitSpacing.xxsmall,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(MinglitRadius.chip),
                  ),
                  child: Text(
                    context.l10n.partyList_badge_draft,
                    // TODO(#2274): labelSmall보다 작은 토큰 없음 — MDS 확장 대기
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (party.location != null) ...[
            const SizedBox(height: MinglitSpacing.xxsmall),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: MinglitIconSize.xsmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: MinglitSpacing.xxsmall),
                Expanded(
                  child: Text(
                    party.location!.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Region 3 — Stats
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRegion extends StatelessWidget {
  const _StatsRegion({required this.entry});

  final PartyWithStats entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              label: '완료',
              count: entry.completedCount,
              unit: '회',
              theme: theme,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: _StatBlock(
              label: '예정',
              count: entry.upcomingCount,
              unit: '회',
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.count,
    required this.unit,
    required this.theme,
  });

  final String label;
  final int count;
  final String unit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Region 4 — Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCtaRegion extends StatelessWidget {
  const _BottomCtaRegion({
    required this.entry,
    required this.onNextEventTap,
    required this.onCreateEventTap,
  });

  final PartyWithStats entry;
  final VoidCallback? onNextEventTap;
  final VoidCallback? onCreateEventTap;

  @override
  Widget build(BuildContext context) {
    final party = entry.party;
    final nextEvent = entry.nextEvent;

    // Variant A: has upcoming events → "다음 이벤트" row
    if (nextEvent != null) {
      return _NextEventRow(event: nextEvent, onTap: onNextEventTap);
    }

    // Variant B: draft status → disabled CTA with info
    if (party.status == 'draft') {
      return const _DraftCtaRow();
    }

    // Variant C: has completed events but no upcoming → "이벤트 생성하기"
    if (entry.completedCount > 0) {
      return _CreateEventRow(onCreateEventTap: onCreateEventTap);
    }

    // Variant D: brand new party, no events → "이벤트 만들기" with sub
    return _NewPartyCtaRow(onCreateEventTap: onCreateEventTap);
  }
}

class _NextEventRow extends StatelessWidget {
  const _NextEventRow({required this.event, this.onTap});

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = event.startTime.difference(DateTime.now()).inDays;
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko',
    ).format(event.startTime);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.small,
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: MinglitIconSize.small,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            Text(
              context.l10n.partyList_nextEvent_label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            Expanded(
              child: Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            MinglitDDayChip(daysUntil: daysUntil),
            const SizedBox(width: MinglitSpacing.xsmall),
            Icon(
              Icons.chevron_right,
              size: MinglitIconSize.small,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateEventRow extends StatelessWidget {
  const _CreateEventRow({this.onCreateEventTap});

  final VoidCallback? onCreateEventTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      child: OutlinedButton.icon(
        onPressed: onCreateEventTap,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.partyList_cta_createEvent),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 36),
        ),
      ),
    );
  }
}

class _NewPartyCtaRow extends StatelessWidget {
  const _NewPartyCtaRow({this.onCreateEventTap});

  final VoidCallback? onCreateEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onCreateEventTap,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.partyList_cta_createEventNew),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xxsmall),
          Text(
            context.l10n.partyList_cta_createEventSub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DraftCtaRow extends StatelessWidget {
  const _DraftCtaRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.partyList_cta_createEventNew),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.xsmall,
                  vertical: MinglitSpacing.xxsmall,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(MinglitRadius.chip),
                ),
                child: Text(
                  context.l10n.partyList_badge_draft,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xxsmall),
          Text(
            context.l10n.partyList_cta_draftSub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: inset horizontal divider between regions
// ─────────────────────────────────────────────────────────────────────────────

class _InsetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: MinglitSpacing.medium,
      endIndent: MinglitSpacing.medium,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
