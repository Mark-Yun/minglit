import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyListItem extends StatelessWidget {
  const PartyListItem({required this.party, required this.onTap, super.key});

  final Party party;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (Title + Icon)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium, // Increased vertical padding
              ),
              color: colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      party.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      // Removed maxLines to allow multiline titles
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            // 2. Body (Image + Info)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  if (party.imageUrl != null)
                    Image.network(
                      party.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(context),
                    )
                  else
                    _buildPlaceholder(context),

                  // Gradient (Bottom-up)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.surface.withValues(alpha: 0),
                          theme.colorScheme.onSurface.withValues(alpha: 0.54),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),

                  // Content Layer
                  Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top-Left: Status Badge
                        _buildStatusBadge(context),
                        const Spacer(),

                        // Bottom-Left: Chips
                        Wrap(
                          spacing: MinglitSpacing.xxsmall,
                          runSpacing: MinglitSpacing.xxsmall,
                          children: [
                            // Location Chip
                            if (party.location != null)
                              _InfoChip(
                                icon: Icons.location_on,
                                label: party.location!.name,
                              )
                            else
                              _InfoChip(
                                icon: Icons.location_off,
                                label:
                                    context.l10n.partyList_message_noLocation,
                              ),

                            // Participants Chip
                            _InfoChip(
                              icon: Icons.people,
                              label: context.l10n
                                  .partyList_chip_maxParticipants(
                                    party.maxParticipants,
                                  ),
                            ),

                            // Condition Chips (Gender/Age)
                            for (final condition in party.conditionSummaries)
                              if (condition != '조건 없음')
                                _InfoChip(
                                  icon: Icons.assignment,
                                  label: condition,
                                ),

                            // Verification Chip
                            if (party.requiredVerificationIds.isNotEmpty)
                              _InfoChip(
                                icon: Icons.verified_user,
                                label: context.l10n
                                    .partyList_chip_requiredVerifications(
                                      party.requiredVerificationIds.length,
                                    ),
                              )
                            else
                              _InfoChip(
                                icon: Icons.verified_user_outlined,
                                label:
                                    context.l10n.partyList_chip_noVerification,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.onSurface,
      child: Center(
        child: Icon(
          Icons.party_mode,
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          size: MinglitIconSize.xlarge * 1.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (party.status) {
      'active' => (
        context.l10n.partyList_badge_active,
        theme.colorScheme.tertiary,
      ),
      'closed' => (
        context.l10n.partyList_badge_closed,
        theme.colorScheme.outline,
      ),
      'draft' => (
        context.l10n.partyList_badge_draft,
        theme.colorScheme.secondary,
      ),
      _ => (party.status, theme.colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MinglitSpacing.xxsmall),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: MinglitIconSize.xsmall * 0.75,
            color: theme.colorScheme.surface,
          ),
          const SizedBox(width: MinglitSpacing.xxsmall),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.surface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
