// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

class MinglitFilePickerUploadButton extends StatelessWidget {
  const MinglitFilePickerUploadButton({
    required this.isUploading,
    required this.label,
    required this.hint,
    this.onTap,
    super.key,
  });

  final bool isUploading;
  final String label;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(MinglitRadius.small),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: MinglitSpacing.small),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
