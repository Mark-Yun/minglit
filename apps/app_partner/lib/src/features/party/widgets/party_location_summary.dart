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
    this.showError = false,
    super.key,
  });

  final Location? location;
  final String? addressDetail;
  final String? directionsGuide;
  final VoidCallback? onEditLocation;
  final VoidCallback? onEditDetail;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (location == null) {
      return Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          border: Border.all(
            color: showError
                ? colorScheme.error.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Text(
              context.l10n.partyDetail_empty_location,
              style: TextStyle(color: showError ? colorScheme.error : null),
            ),
            if (onEditLocation != null) ...[
              const SizedBox(height: MinglitSpacing.medium),
              AddActionCard(
                title: context.l10n.common_button_edit,
                iconData: Icons.edit_location_alt_outlined,
                onTap: onEditLocation!,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Map & Basic Address
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                child: LocationMap(
                  latitude: location!.latitude,
                  longitude: location!.longitude,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location!.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location!.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (onEditLocation != null) ...[
                      const SizedBox(height: MinglitSpacing.small),
                      const Divider(),
                      const SizedBox(height: MinglitSpacing.xsmall),
                      AddActionCard(
                        title: '장소 변경',
                        iconData: Icons.map_outlined,
                        onTap: onEditLocation!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: MinglitSpacing.large),

        // 2. Detail Info (Directions, etc)
        Text(
          context.l10n.partyDetail_section_locationDetail,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (addressDetail != null && addressDetail!.isNotEmpty)
                _buildDetailItem(
                  context,
                  Icons.apartment,
                  context.l10n.partyCreate_label_addressDetail,
                  addressDetail!,
                )
              else if (showError)
                _buildMissingItem(context, '상세 주소가 입력되지 않았습니다.'),

              if (directionsGuide != null && directionsGuide!.isNotEmpty)
                _buildDetailItem(
                  context,
                  Icons.directions,
                  context.l10n.partyCreate_label_directions,
                  directionsGuide!,
                )
              else if (showError)
                _buildMissingItem(context, '오시는 길 안내가 입력되지 않았습니다.'),

              if ((addressDetail == null || addressDetail!.isEmpty) &&
                  (directionsGuide == null || directionsGuide!.isEmpty) &&
                  !showError)
                Padding(
                  padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
                  child: Text(
                    context.l10n.partyDetail_empty_locationDetail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onEditDetail != null) ...[
                const SizedBox(height: MinglitSpacing.xsmall),
                if ((addressDetail?.isNotEmpty ?? false) ||
                    (directionsGuide?.isNotEmpty ?? false))
                  const Divider(),
                const SizedBox(height: MinglitSpacing.xsmall),
                AddActionCard(
                  title: '상세 정보 수정',
                  iconData: Icons.edit_note,
                  onTap: onEditDetail!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(content, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
