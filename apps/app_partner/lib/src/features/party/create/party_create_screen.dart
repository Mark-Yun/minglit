import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_conditions_selector.dart';
import 'package:app_partner/src/features/party/create/widgets/party_contact_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_description_editor.dart';
import 'package:app_partner/src/features/party/create/widgets/party_image_picker.dart';
import 'package:app_partner/src/features/party/create/widgets/party_location_detail_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_location_selector.dart';
import 'package:app_partner/src/features/party/create/widgets/party_ticket_template_editor.dart';
import 'package:app_partner/src/features/party/create/widgets/party_verification_selector.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
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
  final _addressDetailController = TextEditingController();
  final _directionsController = TextEditingController();

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
    _addressDetailController.dispose();
    _directionsController.dispose();
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

  Future<void> _handleLocationSearch() async {
    final coordinator = PartyCreateCoordinator(context);
    final location = await coordinator.goToLocationSearch();
    if (location != null) {
      ref.read(partyCreateControllerProvider.notifier).updateLocation(location);
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
            addressDetail: _addressDetailController.text,
            directionsGuide: _directionsController.text,
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
        final controller = ref.read(partyCreateControllerProvider.notifier);
        final state = ref.read(partyCreateControllerProvider);

        if (partner.contactPhone != null && partner.contactPhone!.isNotEmpty) {
          _phoneController.text = partner.contactPhone!;
          if (!state.enabledContactMethods.contains('phone')) {
            controller.toggleContactMethod('phone');
          }
        }
        if (partner.contactEmail != null && partner.contactEmail!.isNotEmpty) {
          _emailController.text = partner.contactEmail!;
          if (!state.enabledContactMethods.contains('email')) {
            controller.toggleContactMethod('email');
          }
        }
        setState(() => _isDataLoaded = true);
      }
    });

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '파티 기획하기'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.partyCreate_hint_title,
                ),
                validator: controller.validateTitle,
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyCreate_label_description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyDescriptionEditor(
                quillController: _quillController,
                focusNode: _editorFocusNode,
                errorText: state.descriptionError,
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyCreate_label_coverImage,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyImagePicker(
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyCreate_label_location,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyLocationSelector(
                selectedLocation: state.selectedLocation,
                onSearchTap: _handleLocationSearch,
              ),
              const SizedBox(height: MinglitSpacing.large),
              PartyLocationDetailInput(
                addressDetailController: _addressDetailController,
                directionsController: _directionsController,
                enabled: state.selectedLocation != null,
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyCreate_label_capacity,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyCapacityInput(
                minCount: int.tryParse(_minCountController.text) ?? 0,
                maxCount: int.tryParse(_maxCountController.text) ?? 0,
                onMinChanged: (val) =>
                    setState(() => _minCountController.text = val.toString()),
                onMaxChanged: (val) =>
                    setState(() => _maxCountController.text = val.toString()),
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyDetail_section_entranceCondition,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyConditionsSelector(
                conditions: state.conditions,
                onChanged: controller.updateConditions,
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyCreate_label_contact,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyContactInput(
                phoneController: _phoneController,
                emailController: _emailController,
                kakaoController: _kakaoController,
                enabledMethods: state.enabledContactMethods,
                onToggleMethod: controller.toggleContactMethod,
                phoneValidator: controller.validatePhone,
                emailValidator: controller.validateEmail,
              ),
              const SizedBox(height: MinglitSpacing.small),

              Text(
                context.l10n.partyDetail_section_verification,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
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
              const SizedBox(height: MinglitSpacing.large),

              Text(
                context.l10n.partyDetail_section_tickets,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              PartyTicketTemplateEditor(
                ticketTemplates: state.ticketTemplates,
                entryGroups: [
                  PartyEntryGroup(
                    id: 'default',
                    gender: state.conditions['gender'] as String?,
                    birthYearRange:
                        state.conditions['birth_year_range']
                            as Map<String, dynamic>?,
                    requiredVerificationIds: state.selectedVerificationIds,
                  ),
                ],
                onAdd: controller.addTicketTemplate,
                onRemove: controller.removeTicketTemplate,
                onUpdate: controller.updateTicketTemplate,
              ),
              const SizedBox(height: MinglitSpacing.xlarge),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status.isLoading ? null : _submit,
                  child: Text(context.l10n.partyCreate_button_submit),
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
