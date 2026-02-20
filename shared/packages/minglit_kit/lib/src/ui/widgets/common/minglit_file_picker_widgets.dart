part of 'minglit_file_picker.dart';

extension _FilePickerUI on _MinglitFilePickerState {
  Widget buildUploadButton(BuildContext context) {
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

  Widget buildPreviewList(BuildContext context) {
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
