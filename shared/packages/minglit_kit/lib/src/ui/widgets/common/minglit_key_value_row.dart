import 'package:flutter/material.dart';

/// **Minglit Key-Value Row**
///
/// 라벨-값 행을 표시하는 레이아웃 위젯.
/// [bold]가 true이면 값 텍스트가 굵게 표시됩니다.
class MinglitKeyValueRow extends StatelessWidget {
  /// Creates a key-value row with a label and value.
  const MinglitKeyValueRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    super.key,
  });

  /// Left-aligned label text.
  final String label;

  /// Right-aligned value text.
  final String value;

  /// When true, applies bold font weight to the value.
  final bool bold;

  /// Optional color override for the value text.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
