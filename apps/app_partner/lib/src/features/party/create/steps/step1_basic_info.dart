import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/widgets/party_description_input.dart';
import 'package:app_partner/src/features/party/widgets/party_image_editor.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:minglit_kit/minglit_kit.dart';

class Step1BasicInfo extends ConsumerStatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  ConsumerState<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends ConsumerState<Step1BasicInfo> {
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  late final FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();
    final state = ref.read(partyCreateWizardControllerProvider);

    _titleController = TextEditingController(text: state.title);
    _editorFocusNode = FocusNode();

    // Initialize Quill with existing delta or empty
    if (state.description.containsKey('ops')) {
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(state.description['ops'] as List),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = quill.QuillController.basic();
    }

    // Update wizard state whenever quill content changes
    _quillController.addListener(() {
      final json = {'ops': _quillController.document.toDelta().toJson()};
      ref
          .read(partyCreateWizardControllerProvider.notifier)
          .updateDescription(json);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partyCreate_label_title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: context.l10n.partyCreate_hint_title,
            ),
            onChanged: (val) => ref
                .read(partyCreateWizardControllerProvider.notifier)
                .updateTitle(val),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partyCreate_label_description,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          PartyDescriptionInput(
            quillController: _quillController,
            focusNode: _editorFocusNode,
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partyCreate_label_coverImage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          PartyImageEditor(
            imageUrls: state.imageUrls,
            onChanged: (urls, files) {
              ref
                  .read(partyCreateWizardControllerProvider.notifier)
                  .updateImages(imageUrls: urls, newFiles: files);
            },
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            '공개 범위',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('비공개 파티'),
            subtitle: const Text('링크를 가진 사용자만 접근 가능'),
            value: state.visibility == 'private',
            onChanged: (value) {
              ref
                  .read(partyCreateWizardControllerProvider.notifier)
                  .setVisibility(value ? 'private' : 'public');
            },
          ),
        ],
      ),
    );
  }
}
