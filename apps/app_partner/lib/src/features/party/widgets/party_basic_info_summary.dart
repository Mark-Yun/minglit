import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicInfoSummary extends StatelessWidget {
  const PartyBasicInfoSummary({
    required this.title,
    required this.description,
    this.imageFile,
    this.imageUrl,
    this.showError = false,
    this.showFullDescription = false,
    this.showTitle = true,
    super.key,
  });

  final String title;
  final Map<String, dynamic> description;
  final XFile? imageFile;
  final String? imageUrl;
  final bool showError;
  final bool showFullDescription;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ops = description['ops'] as List?;
    final isDescriptionEmpty =
        ops == null ||
        ops.isEmpty ||
        (ops.length == 1 && (ops[0] as Map<String, dynamic>)['insert'] == '\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(
              bottom: MinglitSpacing.medium,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: imageFile != null
                  ? MinglitImage(
                      assetPath: imageFile!.path,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
          ),
        if (showTitle)
          Text(
            title.isEmpty ? context.l10n.wizard_review_noTitle : title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: title.isEmpty && showError ? colorScheme.error : null,
            ),
          ),
        if (showTitle) const SizedBox(height: MinglitSpacing.small),
        if (showFullDescription && !isDescriptionEmpty)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: quill.QuillEditor.basic(
              controller: quill.QuillController(
                document: quill.Document.fromJson(ops),
                selection: const TextSelection.collapsed(offset: 0),
                readOnly: true,
              ),
              config: MinglitQuillTheme.editorConfig(
                context,
                placeholder: '',
              ),
            ),
          )
        else
          Text(
            isDescriptionEmpty
                ? context.l10n.wizard_review_noDescription
                : context.l10n.wizard_review_descriptionDone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDescriptionEmpty && showError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
