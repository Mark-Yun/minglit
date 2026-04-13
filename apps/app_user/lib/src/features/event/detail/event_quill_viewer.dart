part of 'event_detail_page.dart';

class _QuillViewer extends StatelessWidget {
  const _QuillViewer({required this.description});

  final Map<String, dynamic> description;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const Text('상세 소개 정보가 없습니다.');

    final controller = QuillController(
      document: Document.fromJson(description['ops'] as List),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    // Fix #1380: 마지막 줄 descender 잘림 방지 — bottom padding 추가
    return QuillEditor.basic(
      controller: controller,
      config: const QuillEditorConfig(
        padding: EdgeInsets.only(bottom: MinglitSpacing.medium),
      ),
    );
  }
}
