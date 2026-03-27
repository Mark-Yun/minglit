import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

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
            color: colorScheme.surfaceContainerHighest.withValues(alpha: MinglitOpacity.muted),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            child: widget.selectedLocation == null
                ? _buildEmptyState(context)
                : LocationMapView(location: widget.selectedLocation!),
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
              padding: const EdgeInsets.all(MinglitSpacing.medium),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text('파티가 열릴 장소를 선택하세요', style: MinglitTextStyles.infoText(context)),
        ],
      ),
    );
  }
}
