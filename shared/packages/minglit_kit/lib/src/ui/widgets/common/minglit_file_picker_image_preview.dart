// ignore_for_file: type=lint
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

class MinglitFilePickerPreviewList extends StatelessWidget {
  const MinglitFilePickerPreviewList({
    required this.selectedFiles,
    required this.uploadedUrls,
    required this.autoUpload,
    required this.onRemove,
    super.key,
  });

  final List<PlatformFile> selectedFiles;
  final List<String> uploadedUrls;
  final bool autoUpload;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: MinglitSpacing.small),
        itemBuilder: (context, index) {
          final file = selectedFiles[index];
          // Check if this specific file is uploaded (naive check by index)
          final isUploaded = index < uploadedUrls.length;

          return Stack(
            children: [
              MinglitFilePickerImagePreview(file: file),
              if (isUploaded && autoUpload)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MinglitFilePickerImagePreview extends StatelessWidget {
  const MinglitFilePickerImagePreview({
    required this.file,
    super.key,
  });

  final PlatformFile file;

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(
      file.extension?.toLowerCase(),
    );

    if (isImage) {
      ImageProvider provider;
      if (kIsWeb) {
        provider = MemoryImage(file.bytes!);
      } else {
        provider = FileImage(File(file.path!));
      }
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MinglitRadius.small),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.grey),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }
  }
}
