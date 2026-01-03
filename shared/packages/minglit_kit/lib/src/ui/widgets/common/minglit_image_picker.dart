import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A generic image picker widget with preview.
class MinglitImagePicker extends StatelessWidget {
  const MinglitImagePicker({
    required this.onPickImage,
    this.selectedImage,
    this.initialImageUrl,
    this.height = 200,
    this.emptyText = '등록된 이미지가 없습니다',
    this.uploadButtonText = '이미지 업로드',
    this.changeButtonText = '이미지 변경하기',
    super.key,
  });

  final XFile? selectedImage;
  final String? initialImageUrl;
  final VoidCallback onPickImage;
  final double height;
  final String emptyText;
  final String uploadButtonText;
  final String changeButtonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine image provider
    ImageProvider? imageProvider;
    if (selectedImage != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(selectedImage!.path);
      } else {
        imageProvider = FileImage(File(selectedImage!.path));
      }
    } else if (initialImageUrl != null && initialImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(initialImageUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Image Preview Area
        Container(
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            image: imageProvider != null
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageProvider == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: MinglitSpacing.small),
                      Text(
                        emptyText,
                        style: MinglitTextStyles.infoText(context),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: MinglitSpacing.small),

        // 2. Upload Button
        AnimatedContainer(
          duration: MinglitAnimation.fast,
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MinglitRadius.input),
          ),
          child: InkWell(
            onTap: onPickImage,
            borderRadius: BorderRadius.circular(MinglitRadius.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.upload_file,
                    color: colorScheme.tertiary,
                    size: MinglitIconSize.small,
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Text(
                      imageProvider == null
                          ? uploadButtonText
                          : changeButtonText,
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
}
