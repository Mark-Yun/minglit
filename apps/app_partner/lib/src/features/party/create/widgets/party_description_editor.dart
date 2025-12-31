import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:minglit_kit/minglit_kit.dart';

class PartyDescriptionEditor extends StatelessWidget {
  const PartyDescriptionEditor({
    required this.quillController,
    required this.focusNode,
    this.errorText,
    super.key,
  });

  final quill.QuillController quillController;
  final FocusNode focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: MinglitQuillTheme.editorDecoration(context).copyWith(
            border: Border.all(
              color: errorText != null
                  ? colorScheme.error
                  : colorScheme.outlineVariant,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              quill.QuillSimpleToolbar(
                controller: quillController,
                config: MinglitQuillTheme.toolbarConfig(context),
              ),
              Container(
                height: 1,
                color: errorText != null
                    ? colorScheme.error
                    : colorScheme.outlineVariant,
              ),
              SizedBox(
                height: 250,
                child: DefaultTextStyle(
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.normal,
                    color: MinglitColors.textPrimary,
                  ),
                  child: quill.QuillEditor.basic(
                    controller: quillController,
                    focusNode: focusNode,
                    config: MinglitQuillTheme.editorConfig(
                      context,
                      placeholder: '파티의 분위기, 제공되는 음식, 음악 등을 자유롭게 꾸며보세요!',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: MinglitSpacing.xsmall,
              left: MinglitSpacing.small,
            ),
            child: Text(
              errorText!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
