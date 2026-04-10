import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Status Edit Sheet**
///
/// A reusable bottom sheet widget to select/change the party status.
/// Used in Party Detail and potentially in Party Creation Wizard.
class PartyStatusEditSheet extends StatelessWidget {
  const PartyStatusEditSheet({
    required this.currentStatus,
    required this.onStatusSelected,
    this.currentVisibility = 'public',
    this.onVisibilityChanged,
    super.key,
  });

  final String currentStatus;
  final ValueChanged<String> onStatusSelected;
  final String currentVisibility;
  final ValueChanged<String>? onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '운영 상태 변경',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            _buildStatusOption(
              context,
              label: '운영중 (공개)',
              value: 'active',
              description: '유저 앱에 파티가 노출되고 티켓 구매가 가능합니다.',
              icon: Icons.public,
            ),
            _buildStatusOption(
              context,
              label: '임시저장 (비공개)',
              value: 'draft',
              description: '유저 앱에 노출되지 않으며, 관리자만 볼 수 있습니다.',
              icon: Icons.edit_document,
            ),
            _buildStatusOption(
              context,
              label: '종료됨',
              value: 'closed',
              description: '모든 이벤트가 종료되었을 때 사용합니다.',
              icon: Icons.archive_outlined,
            ),
            const Divider(),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '공개 범위',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('비공개'),
              subtitle: const Text('검색/피드에서 숨김'),
              value: currentVisibility == 'private',
              onChanged: (value) {
                onVisibilityChanged?.call(value ? 'private' : 'public');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context, {
    required String label,
    required String value,
    required String description,
    required IconData icon,
  }) {
    final isSelected = currentStatus == value;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? MinglitColors.primary : null,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(MinglitSpacing.small),
        decoration: BoxDecoration(
          color: isSelected
              ? MinglitColors.primary.withValues(
                  alpha: MinglitOpacity.highlight,
                )
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? MinglitColors.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: MinglitColors.primary)
          : null,
      onTap: () => onStatusSelected(value),
    );
  }
}
