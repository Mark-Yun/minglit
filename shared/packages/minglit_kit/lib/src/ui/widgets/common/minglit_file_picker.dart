import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Minglit File Picker**
///
/// A universal file picker widget supporting Images and Documents (PDF).
/// Handles platform differences (Web/Native) and input sources.
/// Optionally supports automatic uploading to Supabase Storage.
class MinglitFilePicker extends ConsumerStatefulWidget {
  const MinglitFilePicker({
    required this.onFilesSelected,
    super.key,
    this.initialUrls = const [],
    this.allowMultiple = false,
    this.fileType = FileType.image,
    this.maxFileSizeMb = 10,
    this.label = '파일 업로드',
    this.hint = '이미지 또는 PDF 파일을 선택해주세요',
    this.autoUpload = false,
    this.uploadBucket,
    this.uploadPathPrefix,
    this.onUploadComplete,
  });

  final void Function(List<PlatformFile> files) onFilesSelected;
  final List<String> initialUrls;
  final bool allowMultiple;
  final FileType fileType;
  final int maxFileSizeMb;
  final String label;
  final String hint;

  // Auto-Upload Options
  final bool autoUpload;
  final String? uploadBucket;
  final String? uploadPathPrefix;
  final void Function(List<String> urls)? onUploadComplete;

  @override
  ConsumerState<MinglitFilePicker> createState() => _MinglitFilePickerState();
}

class _MinglitFilePickerState extends ConsumerState<MinglitFilePicker> {
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _uploadedUrls = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedUrls.addAll(widget.initialUrls);
  }

  Future<void> _pickFiles() async {
    // If specific image picker is requested on Mobile
    if (!kIsWeb && widget.fileType == FileType.image) {
      await _showImageSourceSheet();
      return;
    }

    // Default File Picker
    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.fileType,
        allowMultiple: widget.allowMultiple,
        withData: kIsWeb, // Web needs bytes
      );

      if (result != null) {
        await _processFiles(result.files);
      }
    } on Exception catch (e) {
      debugPrint('FilePicker Error: $e');
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickImage(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickImage(ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (widget.allowMultiple && source == ImageSource.gallery) {
        final images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          final files = images
              .map(
                (e) => PlatformFile(
                  name: e.name,
                  size: 0, // Unknown size immediately
                  path: e.path,
                ),
              )
              .toList();
          await _processFiles(files);
        }
      } else {
        final image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          final file = PlatformFile(
            name: image.name,
            size: 0,
            path: image.path,
          );
          await _processFiles([file]);
        }
      }
    } on Exception catch (e) {
      debugPrint('ImagePicker Error: $e');
    }
  }

  Future<void> _processFiles(List<PlatformFile> newFiles) async {
    setState(() {
      if (!widget.allowMultiple) {
        _selectedFiles.clear();
        _uploadedUrls.clear(); // Clear old urls for single mode
      }
      _selectedFiles.addAll(newFiles);
    });
    widget.onFilesSelected(_selectedFiles);

    if (widget.autoUpload && widget.uploadBucket != null) {
      await _uploadFiles(newFiles);
    }
  }

  Future<void> _uploadFiles(List<PlatformFile> files) async {
    setState(() => _isUploading = true);
    try {
      final repo = ref.read(storageRepositoryProvider);
      final newUrls = <String>[];

      for (final file in files) {
        // Convert PlatformFile to XFile for compatibility
        XFile xFile;
        if (kIsWeb) {
          xFile = XFile.fromData(file.bytes!, name: file.name);
        } else {
          xFile = XFile(file.path!);
        }

        final url = await repo.uploadFile(
          file: xFile,
          bucket: widget.uploadBucket!,
          pathPrefix: widget.uploadPathPrefix,
        );
        newUrls.add(url);
      }

      setState(() {
        _uploadedUrls.addAll(newUrls);
      });
      widget.onUploadComplete?.call(_uploadedUrls);
    } on Object catch (e) {
      debugPrint('Auto-upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 업로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      // If we have matching URLs (assuming ordered list), remove them too
      if (index < _uploadedUrls.length) {
        _uploadedUrls.removeAt(index);
      }
    });
    widget.onFilesSelected(_selectedFiles);
    widget.onUploadComplete?.call(_uploadedUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUploadButton(context),
        if (_isUploading) ...[
          const SizedBox(height: MinglitSpacing.small),
          const LinearProgressIndicator(),
        ],
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          _buildPreviewList(context),
        ],
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isUploading ? null : _pickFiles,
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
                widget.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.hint,
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

  Widget _buildPreviewList(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: MinglitSpacing.small),
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          // Check if this specific file is uploaded (naive check by index)
          final isUploaded = index < _uploadedUrls.length;

          return Stack(
            children: [
              _buildFileThumbnail(context, file),
              if (isUploaded && widget.autoUpload)
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
                  onTap: () => _removeFile(index),
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

  Widget _buildFileThumbnail(BuildContext context, PlatformFile file) {
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
