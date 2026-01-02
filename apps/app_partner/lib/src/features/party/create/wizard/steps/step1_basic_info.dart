import 'package:app_partner/src/features/party/create/widgets/party_description_editor.dart';
import 'package:app_partner/src/features/party/create/widgets/party_image_picker.dart';
import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(partyCreateWizardControllerProvider.notifier).updateImage(image);
    }
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
          const PartySectionTitle('파티 제목'),
          TextFormField(
            controller: _titleController,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.normal,
            ),
            decoration: const InputDecoration(hintText: '예: 강남역 불금 와인 파티'),
            onChanged: (val) => ref
                .read(partyCreateWizardControllerProvider.notifier)
                .updateTitle(val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          const PartySectionTitle('상세 설명'),
          PartyDescriptionEditor(
            quillController: _quillController,
            focusNode: _editorFocusNode,
          ),
          const SizedBox(height: MinglitSpacing.large),

          const PartySectionTitle('커버 이미지'),
          PartyImagePicker(
            selectedImage: state.imageFile,
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }
}
