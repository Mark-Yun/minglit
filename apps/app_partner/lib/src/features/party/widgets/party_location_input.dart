import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class PartyLocationInput extends StatefulWidget {
  const PartyLocationInput({
    required this.selectedLocation,
    required this.onSearchTap,
    super.key,
  });

  final Location? selectedLocation;
  final VoidCallback onSearchTap;

  @override
  State<PartyLocationInput> createState() => _PartyLocationInputState();
}

class _PartyLocationInputState extends State<PartyLocationInput> {
  void _copyAddress(String address) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Map View Area / Info Area
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            child: widget.selectedLocation == null
                ? _buildEmptyState(context)
                : _buildSelectedState(context),
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),

        // 2. Search Button (Slim Refined Card)
        AnimatedContainer(
          duration: MinglitAnimation.fast,
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MinglitRadius.input),
          ),
          child: InkWell(
            onTap: widget.onSearchTap,
            borderRadius: BorderRadius.circular(MinglitRadius.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: colorScheme.tertiary,
                    size: MinglitIconSize.small,
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Text(
                      widget.selectedLocation == null ? '위치 검색하기' : '장소 변경하기',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.tertiary.withValues(alpha: 0.6),
                    size: MinglitIconSize.medium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
              alpha: 0.5,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '파티가 열릴 장소를 선택하세요',
            style: MinglitTextStyles.infoText(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = widget.selectedLocation;

    if (loc == null) return const SizedBox.shrink();

    return Stack(
      children: [
        LocationMap(
          latitude: loc.latitude,
          longitude: loc.longitude,
        ),
        // Location Info Overlay
        Positioned(
          left: MinglitSpacing.medium,
          right: MinglitSpacing.medium,
          bottom: MinglitSpacing.medium,
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
                        loc.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyAddress(loc.address),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.copy,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                _openExternalMap(loc.latitude, loc.longitude),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
