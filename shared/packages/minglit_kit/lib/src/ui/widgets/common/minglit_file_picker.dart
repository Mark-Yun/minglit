// ignore_for_file: type=lint
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

import 'minglit_file_picker_image_preview.dart';
import 'minglit_file_picker_upload_button.dart';
import 'minglit_image_source_sheet.dart';

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

  final void Function(List<PlatformFile> files) onFilesSelected;
  final List<String> initialUrls;
  final bool allowMultiple;
  final FileType fileType;
  final int maxFileSizeMb;
  final String label;
  final String hint;
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
      builder: (context) => MinglitImageSourceSheet(
        onSourceSelected: (source) {
          unawaited(_pickImage(source));
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (widget.allowMultiple && source == ImageSource.gallery) {
        final images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          final files = images
              .map((e) => PlatformFile(name: e.name, size: 0, path: e.path))
              .toList();
          await _processFiles(files);
        }
      } else {
        final image = await _imagePicker.pickImage(source: source);
        if (image != null)
          await _processFiles([
            PlatformFile(name: image.name, size: 0, path: image.path),
          ]);
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

    // Fix #382: uploadBucket을 local variable로 캡처하여 _uploadFiles 내 강제 언래핑 방지
    final bucket = widget.uploadBucket;
    if (widget.autoUpload && bucket != null) {
      await _uploadFiles(newFiles, bucket);
    }
  }

  Future<void> _uploadFiles(List<PlatformFile> files, String bucket) async {
    setState(() => _isUploading = true);
    try {
      final repo = ref.read(storageRepositoryProvider);
      final newUrls = <String>[];

      for (final file in files) {
        // Fix #270: 플랫폼별 bytes/path null 가능 — null이면 건너뛰기
        if (kIsWeb && file.bytes == null) continue;
        if (!kIsWeb && file.path == null) continue;
        // Convert PlatformFile to XFile for compatibility
        // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
        final bytes = file.bytes;
        final path = file.path;
        final xFile = kIsWeb
            ? XFile.fromData(bytes!, name: file.name)
            : XFile(path!);
        final url = await repo.uploadFile(
          file: xFile,
          bucket: bucket,
          pathPrefix: widget.uploadPathPrefix,
        );
        newUrls.add(url);
      }

      setState(() => _uploadedUrls.addAll(newUrls));
      widget.onUploadComplete?.call(_uploadedUrls);
    } on Object catch (e) {
      debugPrint('Auto-upload failed: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('파일 업로드 실패: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (index < _uploadedUrls.length) _uploadedUrls.removeAt(index);
    });
    widget.onFilesSelected(_selectedFiles);
    widget.onUploadComplete?.call(_uploadedUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinglitFilePickerUploadButton(
          isUploading: _isUploading,
          label: widget.label,
          hint: widget.hint,
          onTap: _isUploading ? null : _pickFiles,
        ),
        if (_isUploading) ...[
          const SizedBox(height: MinglitSpacing.small),
          const LinearProgressIndicator(),
        ],
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          MinglitFilePickerPreviewList(
            selectedFiles: _selectedFiles,
            uploadedUrls: _uploadedUrls,
            autoUpload: widget.autoUpload,
            onRemove: _removeFile,
          ),
        ],
      ],
    );
  }
}
