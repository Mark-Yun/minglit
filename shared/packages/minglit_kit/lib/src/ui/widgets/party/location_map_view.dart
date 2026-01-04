import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// **Location Map View**
///
/// A reusable widget that displays a map with a floating info card overlay.
/// Commonly used in Party/Event lists and details.
class LocationMapView extends StatelessWidget {
  const LocationMapView({
    required this.location,
    this.height = 200,
    this.showExternalMapButton = true,
    this.showCopyButton = true,
    super.key,
  });

  final Location location;
  final double height;
  final bool showExternalMapButton;
  final bool showCopyButton;

  void _copyAddress(BuildContext context, String address) {
    unawaited(Clipboard.setData(ClipboardData(text: address)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('주소가 클립보드에 복사되었습니다.')),
    );
  }

  Future<void> _openExternalMap(double lat, double lng) async {
    final url = Uri.parse('https://map.kakao.com/link/map/$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // 1. Base Map
          LocationMap(
            latitude: location.latitude,
            longitude: location.longitude,
          ),

          // 2. Info Overlay Card
          Positioned(
            left: MinglitSpacing.small,
            right: MinglitSpacing.small,
            bottom: MinglitSpacing.small,
            child: Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: colorScheme.primary,
                    size: MinglitIconSize.medium,
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showCopyButton || showExternalMapButton) ...[
                    const SizedBox(width: MinglitSpacing.small),
                    if (showCopyButton)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => _copyAddress(context, location.address),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    if (showExternalMapButton) ...[
                      const SizedBox(width: MinglitSpacing.small),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        onPressed: () =>
                            _openExternalMap(location.latitude, location.longitude),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
