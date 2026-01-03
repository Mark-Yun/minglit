import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicInfoSummary extends StatelessWidget {
  const PartyBasicInfoSummary({
    required this.title,
    required this.description,
    this.imageFile,
    this.showError = false,
    super.key,
  });

  final String title;
  final Map<String, dynamic> description;
  final XFile? imageFile;
  final bool showError;

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
        if (imageFile != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: MinglitSpacing.medium,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: MinglitImage(
                assetPath: imageFile!.path,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Text(
          title.isEmpty ? context.l10n.wizard_review_noTitle : title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: title.isEmpty && showError ? colorScheme.error : null,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
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
