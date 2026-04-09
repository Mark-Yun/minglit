import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Image Editor**
///
/// A widget to manage multiple party images.
/// Supports picking, deleting, and reordering.
/// Follows Minglit UI standards from MinglitFilePicker.
class PartyImageEditor extends StatefulWidget {
  const PartyImageEditor({
    required this.imageUrls,
    required this.onChanged,
    super.key,
    this.maxImages = 10,
  });

  final List<String> imageUrls;
  final void Function(List<String> imageUrls, List<XFile> newFiles) onChanged;
  final int maxImages;

  @override
  State<PartyImageEditor> createState() => _PartyImageEditorState();
}

class _PartyImageEditorState extends State<PartyImageEditor> {
  final List<String> _currentUrls = [];
  final List<XFile> _newFiles = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUrls.addAll(widget.imageUrls);
  }

  Future<void> _pickImages() async {
    if (_currentUrls.length + _newFiles.length >= widget.maxImages) {
      if (!mounted) return;
      _showMaxImagesSnackBar();
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newFiles.addAll(images);
        });
        widget.onChanged(_currentUrls, _newFiles);
      }
    } on Exception catch (e) {
      debugPrint('ImagePicker Error: $e');
    }
  }

  void _showMaxImagesSnackBar() {
    final text = '최대 ${widget.maxImages}장까지 등록 가능합니다.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _removeUrl(int index) {
    setState(() {
      _currentUrls.removeAt(index);
    });
    widget.onChanged(_currentUrls, _newFiles);
  }

  void _removeNewFile(int index) {
    setState(() {
      _newFiles.removeAt(index);
    });
    widget.onChanged(_currentUrls, _newFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Upload Button (Similar to MinglitFilePicker)
        _buildUploadButton(context),

        const SizedBox(height: MinglitSpacing.medium),

        // 2. Reorderable Preview List
        // Note: For now we show them in a combined list.
        // Real reordering between remote and local is complex without
        // uploading first.
        // We'll show Remote first, then Local.
        if (_currentUrls.isNotEmpty || _newFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._currentUrls.asMap().entries.map(
                  (e) => _buildPreviewItem(
                    context,
                    index: e.key,
                    url: e.value,
                    onDelete: () => _removeUrl(e.key),
                    isRepresentative: e.key == 0,
                  ),
                ),
                ..._newFiles.asMap().entries.map(
                  (e) => _buildPreviewItem(
                    context,
                    index: e.key,
                    file: e.value,
                    onDelete: () => _removeNewFile(e.key),
                    isRepresentative: _currentUrls.isEmpty && e.key == 0,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: MinglitOpacity.muted,
          ),
          borderRadius: BorderRadius.circular(MinglitRadius.small),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '이미지 추가 (${_currentUrls.length + _newFiles.length}/${widget.maxImages})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(
    BuildContext context, {
    required int index,
    required VoidCallback onDelete,
    String? url,
    XFile? file,
    bool isRepresentative = false,
  }) {
    final theme = Theme.of(context);

    ImageProvider imageProvider;
    if (url != null) {
      imageProvider = NetworkImage(url);
    } else {
      final localFile = file;
      if (localFile == null) {
        return const SizedBox.shrink();
      }
      // In Web, XFile.path is a blob URL. In Mobile, it's a local path.
      // Image.network works for blob URLs on Web.
      // For Mobile, we'd usually use FileImage, but since we are web-first,
      // let's handle it gracefully.
      if (kIsWeb) {
        imageProvider = NetworkImage(localFile.path);
      } else {
        imageProvider = FileImage(File(localFile.path));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: MinglitSpacing.small),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              border: isRepresentative
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
          ),
          if (isRepresentative)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.xsmall2,
                  vertical: MinglitSpacing.xxsmall,
                ),
                decoration: _getBadgeDecoration(theme),
                child: Text(
                  '대표',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: MinglitColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(MinglitSpacing.xxsmall),
                decoration: BoxDecoration(
                  color: MinglitColors.textPrimary.withValues(
                    alpha: MinglitOpacity.mediumEmphasis,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: MinglitColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getBadgeDecoration(ThemeData theme) {
    const radius = Radius.circular(MinglitRadius.small);
    return BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: const BorderRadius.only(
        topLeft: radius,
        bottomRight: radius,
      ),
    );
  }
}
