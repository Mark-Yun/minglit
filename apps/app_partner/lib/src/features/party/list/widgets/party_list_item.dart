import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyListItem extends StatelessWidget {
  const PartyListItem({
    required this.party,
    required this.onTap,
    super.key,
  });

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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                        stops: [0.6, 1.0],
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
                          spacing: 6,
                          runSpacing: 6,
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

                            // Condition Chip (Gender/Age)
                            if (party.summaryCondition != '조건 없음')
                              _InfoChip(
                                icon: Icons.assignment,
                                label: party.summaryCondition,
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
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.party_mode,
          color: Colors.white.withValues(alpha: 0.2),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (label, color) = switch (party.status) {
      'active' => (context.l10n.partyList_badge_active, Colors.green),
      'closed' => (context.l10n.partyList_badge_closed, Colors.grey),
      'draft' => (context.l10n.partyList_badge_draft, Colors.orange),
      _ => (party.status, Colors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
