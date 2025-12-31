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
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      child: Material(
        color: colorScheme.surface,
        child: InkWell(
          onTap: onPickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              image: selectedImage != null
                  ? DecorationImage(
                      image: kIsWeb
                          ? NetworkImage(selectedImage!.path)
                          : FileImage(File(selectedImage!.path))
                                as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: MinglitSpacing.small),
                      Text(
                        '터치하여 커버 이미지를 등록하세요',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
