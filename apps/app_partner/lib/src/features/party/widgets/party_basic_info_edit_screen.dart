import 'package:app_partner/src/features/party/widgets/party_description_input.dart';
import 'package:app_partner/src/features/party/widgets/party_image_editor.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicInfoEditScreen extends ConsumerStatefulWidget {
  const PartyBasicInfoEditScreen({
    required this.party,
    required this.onSave,
    super.key,
  });

  final Party party;
  final void Function(
    String title,
    Map<String, dynamic> description,
    List<String> imageUrls,
    List<XFile> newImages,
  )
  onSave;

  @override
  ConsumerState<PartyBasicInfoEditScreen> createState() =>
      _PartyBasicInfoEditScreenState();
}

class _PartyBasicInfoEditScreenState
    extends ConsumerState<PartyBasicInfoEditScreen> {
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  final _quillFocusNode = FocusNode();
  
  late List<String> _currentImageUrls;
  List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.party.title);
    _currentImageUrls = List<String>.from(widget.party.imageUrls);
    
    final ops = widget.party.description?['ops'] as List<dynamic>?;
    _quillController = ops != null
        ? quill.QuillController(
            document: quill.Document.fromJson(ops),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _quillFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '${context.l10n.wizard_review_basicInfo} 수정',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Editor
            Text(
              context.l10n.partyCreate_label_coverImage,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            PartyImageEditor(
              imageUrls: _currentImageUrls,
              onChanged: (urls, files) {
                _currentImageUrls = urls;
                _newImages = files;
              },
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            // 2. Title Input
            Text(
              context.l10n.partyCreate_label_title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: context.l10n.partyCreate_hint_title,
              ),
            ),
            const SizedBox(height: MinglitSpacing.xlarge),

            // 3. Description Input
            Text(
              context.l10n.partyCreate_label_description,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            PartyDescriptionInput(
              quillController: _quillController,
              focusNode: _quillFocusNode,
            ),
            const SizedBox(height: MinglitSpacing.xlarge),

            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _titleController.text, 
                  {
                    'ops': _quillController.document.toDelta().toJson(),
                  }, 
                  _currentImageUrls,
                  _newImages,
                );
                Navigator.pop(context);
              },
              child: Text(context.l10n.common_button_save),
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],
        ),
      ),
    );
  }
}
