part of 'minglit_theme.dart';

class MinglitQuillTheme {
  static QuillSimpleToolbarConfig toolbarConfig(BuildContext context) {
    return const QuillSimpleToolbarConfig(
      showFontFamily: false,
      showFontSize: false,
      showSearchButton: false,
      showInlineCode: false,
      showSubscript: false,
      showSuperscript: false,
      showSmallButton: true,
      showAlignmentButtons: true,
      multiRowsDisplay: false,
    );
  }

  static QuillEditorConfig editorConfig(
    BuildContext context, {
    required String placeholder,
  }) {
    return QuillEditorConfig(
      placeholder: placeholder,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
    );
  }

  static BoxDecoration editorDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(MinglitRadius.input),
      color: colorScheme.surface,
    );
  }
}
