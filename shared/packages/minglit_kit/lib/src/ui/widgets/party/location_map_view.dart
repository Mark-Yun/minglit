import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
// Fix #108: Use conditional import to load the correct platform implementation
// instead of always loading the stub placeholder.
import 'package:minglit_kit/src/ui/widgets/map/location_map.dart'
    if (dart.library.html) 'package:minglit_kit/src/ui/widgets/map/location_map_web.dart'
    if (dart.library.io) 'package:minglit_kit/src/ui/widgets/map/location_map_mobile.dart';
import 'package:url_launcher/url_launcher.dart';

/// **Location Map View**
///
/// A reusable widget that displays a map with a floating info card overlay.
/// The overlay card contains the location name and address.
class LocationMapView extends StatelessWidget {
  /// Creates a map view with an address overlay.
  const LocationMapView({
    required this.location,
    this.height = 200,
    this.showExternalMapButton = true,
    this.showCopyButton = true,
    this.trailing,
    super.key,
  });

  /// Location data to display.
  final Location location;

  /// Height of the map container.
  final double height;

  /// Whether to show a button to open external maps.
  final bool showExternalMapButton;

  /// Whether to show a copy-to-clipboard button.
  final bool showCopyButton;

  /// Optional trailing widget in the overlay.
  final Widget? trailing;

  Future<void> _openInKakaoMap() async {
    final url = Uri.parse(
      'https://map.kakao.com/link/map/${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: location.address));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소가 클립보드에 복사되었습니다.')),
      );
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
                    color: MinglitColors.textPrimary.withValues(alpha: 0.05),
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
                  if (trailing != null)
                    trailing!
                  else if (showCopyButton || showExternalMapButton) ...[
                    const SizedBox(width: MinglitSpacing.small),
                    if (showCopyButton)
                      _ActionButton(
                        icon: Icons.copy,
                        onPressed: () => _copyToClipboard(context),
                      ),
                    if (showExternalMapButton) ...[
                      const SizedBox(width: MinglitSpacing.small),
                      _ActionButton(
                        icon: Icons.open_in_new,
                        onPressed: _openInKakaoMap,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}
