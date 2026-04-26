part of 'minglit_theme.dart';

/// Quill editor theme configuration for Minglit.
class MinglitQuillTheme {
  /// Returns the default toolbar configuration.
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

  /// Returns the default editor configuration with the given [placeholder].
  static QuillEditorConfig editorConfig(
    BuildContext context, {
    required String placeholder,
  }) {
    return QuillEditorConfig(
      placeholder: placeholder,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
    );
  }

  /// Returns the decoration for the editor container.
  static BoxDecoration editorDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(MinglitRadius.input),
      color: colorScheme.surface,
    );
  }
}
