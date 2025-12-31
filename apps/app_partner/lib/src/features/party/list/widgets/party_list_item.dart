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
      margin: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (party.imageUrl != null)
              Image.network(
                party.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.party_mode,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          party.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusChip(status: party.status),
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    '최소 ${party.minConfirmedCount}명 / 최대 ${party.maxParticipants}명',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bgColor, textColor) = switch (status) {
      'active' => ('운영중', Colors.green[50], Colors.green[700]),
      'draft' => ('준비중', Colors.grey[100], Colors.grey[700]),
      'closed' => ('종료', Colors.red[50], Colors.red[700]),
      _ => (
        status,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
