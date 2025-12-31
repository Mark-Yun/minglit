import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_contact_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_description_editor.dart';
import 'package:app_partner/src/features/party/create/widgets/party_image_picker.dart';
import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:app_partner/src/features/party/create/widgets/party_verification_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateScreen extends ConsumerStatefulWidget {
  const PartyCreateScreen({super.key});

  @override
  ConsumerState<PartyCreateScreen> createState() => _PartyCreateScreenState();
}

class _PartyCreateScreenState extends ConsumerState<PartyCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  final _minCountController = TextEditingController(text: '10');
  final _maxCountController = TextEditingController(text: '30');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _kakaoController = TextEditingController();

  // State
  XFile? _selectedImage;
  bool _isDataLoaded = false;
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _minCountController.dispose();
    _maxCountController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final descriptionJson = {
      'ops': _quillController.document.toDelta().toJson(),
    };

    final coordinator = PartyCreateCoordinator(context);
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();

    try {
      await ref
          .read(partyCreateControllerProvider.notifier)
          .createParty(
            title: _titleController.text,
            description: descriptionJson,
            minConfirmedCount: int.tryParse(_minCountController.text) ?? 0,
            maxParticipants: int.tryParse(_maxCountController.text) ?? 0,
            contactPhone: _phoneController.text,
            contactEmail: _emailController.text,
            contactKakao: _kakaoController.text.isNotEmpty
                ? _kakaoController.text
                : null,
            imageFile: _selectedImage,
          );

      final state = ref.read(partyCreateControllerProvider);
      if (state.status.hasError) {
        coordinator.onError(state.status.error! as Exception);
      } else {
        coordinator.onPartyCreated();
      }
    } on Exception catch (e) {
      coordinator.onError(e);
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(partyCreateControllerProvider);
    final controller = ref.read(partyCreateControllerProvider.notifier);
    final verificationsAsync = ref.watch(partyVerificationTypesProvider);
    final partnerInfoAsync = ref.watch(currentPartnerInfoProvider);

    // Auto-fill partner info once loaded
    ref.listen(currentPartnerInfoProvider, (previous, next) {
      if (next.value != null && !_isDataLoaded) {
        final partner = next.value!;
        if (partner.contactPhone != null) {
          _phoneController.text = partner.contactPhone!;
        }
        if (partner.contactEmail != null) {
          _emailController.text = partner.contactEmail!;
        }
        setState(() => _isDataLoaded = true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('파티 기획하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
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
                validator: controller.validateTitle,
              ),
              const SizedBox(height: MinglitSpacing.large),

              const PartySectionTitle('상세 설명'),
              PartyDescriptionEditor(
                quillController: _quillController,
                focusNode: _editorFocusNode,
                errorText: state.descriptionError,
              ),
              const SizedBox(height: MinglitSpacing.large),

              const PartySectionTitle('커버 이미지'),
              PartyImagePicker(
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: MinglitSpacing.large),

              const PartySectionTitle('모집 인원'),
              PartyCapacityInput(
                minController: _minCountController,
                maxController: _maxCountController,
                controller: controller,
              ),
              const SizedBox(height: MinglitSpacing.large),

              const PartySectionTitle('문의 연락처'),
              if (partnerInfoAsync.isLoading)
                Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.small),
                  child: Text(
                    '파트너 정보 불러오는 중...',
                    style: MinglitTextStyles.infoText(context),
                  ),
                ),
              PartyContactInput(
                phoneController: _phoneController,
                emailController: _emailController,
                kakaoController: _kakaoController,
                state: state,
                controller: controller,
              ),
              const SizedBox(height: MinglitSpacing.small),

              const PartySectionTitle('참가 자격 (인증)'),
              PartyVerificationSelector(
                verificationsAsync: verificationsAsync,
                selectedVerificationIds: state.selectedVerificationIds,
                onToggle: controller.toggleVerification,
                onAddTap: () {
                  final partnerId = partnerInfoAsync.value?.id;
                  PartyCreateCoordinator(
                    context,
                  ).goToCreateVerification(partnerId);
                },
              ),
              const SizedBox(height: MinglitSpacing.xlarge),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status.isLoading ? null : _submit,
                  child: const Text('파티 생성 완료'),
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}
