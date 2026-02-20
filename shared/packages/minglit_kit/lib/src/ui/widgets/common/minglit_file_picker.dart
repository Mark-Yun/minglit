import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

part 'minglit_file_picker_widgets.dart';

/// **Minglit File Picker**
///
/// A universal file picker widget supporting Images and Documents (PDF).
/// Handles platform differences (Web/Native) and input sources.
/// Optionally supports automatic uploading to Supabase Storage.
class MinglitFilePicker extends ConsumerStatefulWidget {
  /// Creates a file picker with optional auto-upload support.
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

  /// Callback invoked when files are selected.
  final void Function(List<PlatformFile> files) onFilesSelected;

  /// URLs to show as already uploaded selections.
  final List<String> initialUrls;

  /// Whether to allow selecting multiple files.
  final bool allowMultiple;

  /// File type filter for the picker.
  final FileType fileType;

  /// Maximum file size in megabytes.
  final int maxFileSizeMb;

  /// Title shown in the upload button area.
  final String label;

  /// Helper text shown under the upload title.
  final String hint;

  // Auto-Upload Options
  /// Whether selected files should upload automatically.
  final bool autoUpload;

  /// Storage bucket used for auto-upload.
  final String? uploadBucket;

  /// Optional path prefix to prepend on upload.
  final String? uploadPathPrefix;

  /// Callback invoked when uploads complete.
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
        buildUploadButton(context),
        if (_isUploading) ...[
          const SizedBox(height: MinglitSpacing.small),
          const LinearProgressIndicator(),
        ],
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          buildPreviewList(context),
        ],
      ],
    );
  }
}
