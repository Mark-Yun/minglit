import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Location Summary**
///
/// Displays location name, address, map, and directions.
/// Reused in Party Detail and Review steps.
class PartyLocationSummary extends StatelessWidget {
  const PartyLocationSummary({
    required this.location,
    this.addressDetail,
    this.directionsGuide,
    this.onEditLocation,
    this.onEditDetail,
    super.key,
  });

  final Location? location;
  final String? addressDetail;
  final String? directionsGuide;
  final VoidCallback? onEditLocation;
  final VoidCallback? onEditDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (location == null) {
      final emptyText = Text(
        context.l10n.partyDetail_empty_location,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );

      if (onEditLocation == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: emptyText,
        );
      }

      return Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            emptyText,
            const SizedBox(height: MinglitSpacing.medium),
            AddActionCard(
              title: context.l10n.common_button_edit,
              iconData: Icons.edit_location_alt_outlined,
              onTap: onEditLocation!,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Map View with Basic Address Overlay (Reusable Widget)
        ClipRRect(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          child: LocationMapView(
            location: location!,
            showExternalMapButton: false, // Cleaner view for summary
            showCopyButton: false,
          ),
        ),

        // 2. Detail Info (Address Detail & Directions) - Shown below map
        if (addressDetail != null && addressDetail!.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          _buildDetailItem(
            context,
            Icons.apartment,
            addressDetail!,
          ),
        ],
        if (directionsGuide != null && directionsGuide!.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.xxsmall),
          _buildDetailItem(
            context,
            Icons.directions,
            directionsGuide!,
          ),
        ],

        // 3. Edit Action (Separated by divider)
        if (onEditLocation != null || onEditDetail != null) ...[
          const SizedBox(height: MinglitSpacing.medium),
          const Divider(),
          const SizedBox(height: MinglitSpacing.xsmall),
          AddActionCard(
            title: '장소 정보 수정',
            iconData: Icons.map_outlined,
            onTap: onEditLocation ?? onEditDetail!,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String content,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
