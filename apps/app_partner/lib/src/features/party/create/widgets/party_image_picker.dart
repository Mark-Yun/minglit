import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyImagePicker extends StatelessWidget {
  const PartyImagePicker({
    required this.selectedImage,
    required this.onPickImage,
    super.key,
  });

  final XFile? selectedImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Image Preview Area
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            image: selectedImage != null
                ? DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(selectedImage!.path)
                        : FileImage(File(selectedImage!.path)) as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: selectedImage == null
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
                        '등록된 이미지가 없습니다',
                        style: MinglitTextStyles.infoText(context),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: MinglitSpacing.small),

        // 2. Upload Button (Consistent with Location/Verification)
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
                      selectedImage == null ? '이미지 업로드' : '이미지 변경하기',
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