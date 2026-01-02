import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_contact_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step3CapacityContact extends ConsumerStatefulWidget {
  const Step3CapacityContact({super.key});

  @override
  ConsumerState<Step3CapacityContact> createState() =>
      _Step3CapacityContactState();
}

class _Step3CapacityContactState extends ConsumerState<Step3CapacityContact> {
  late final TextEditingController _minCountController;
  late final TextEditingController _maxCountController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _kakaoController;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(partyCreateWizardControllerProvider);

    _minCountController = TextEditingController(
      text: state.minConfirmedCount.toString(),
    );
    _maxCountController = TextEditingController(
      text: state.maxParticipants.toString(),
    );
    _phoneController = TextEditingController(text: state.contactPhone);
    _emailController = TextEditingController(text: state.contactEmail);
    _kakaoController = TextEditingController(text: state.contactKakao ?? '');

    // Sync enabled methods with actual data if not set yet (or start clean)
    // If it's the first visit and data is empty, we might want to disable them.
    // But since state has default {'phone', 'email'}, let's respect user choice
    // if they navigated back and forth.
    // However, if we want to start 'disabled' if empty, we need to check here.

    // For now, let's keep the existing logic but ensure auto-fill toggles it on
    // .
  }

  @override
  void dispose() {
    _minCountController.dispose();
    _maxCountController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);

    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);

    final partnerInfoAsync = ref.watch(currentPartnerInfoProvider);

    // Auto-fill partner info if not already loaded or entered

    ref.listen(currentPartnerInfoProvider, (previous, next) {
      if (next.hasValue &&
          next.value != null &&
          !_isDataLoaded &&
          _phoneController.text.isEmpty) {
        final partner = next.value!;

        if (partner.contactPhone != null && partner.contactPhone!.isNotEmpty) {
          _phoneController.text = partner.contactPhone!;

          notifier.updateContactPhone(partner.contactPhone!);

          // Ensure method is enabled

          if (!state.enabledContactMethods.contains('phone')) {
            notifier.toggleContactMethod('phone');
          }
        }

        if (partner.contactEmail != null && partner.contactEmail!.isNotEmpty) {
          _emailController.text = partner.contactEmail!;

          notifier.updateContactEmail(partner.contactEmail!);

          // Ensure method is enabled

          if (!state.enabledContactMethods.contains('email')) {
            notifier.toggleContactMethod('email');
          }
        }

        setState(() => _isDataLoaded = true);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PartySectionTitle(context.l10n.partyCreate_label_capacity),
          PartyCapacityInput(
            minController: _minCountController,
            maxController: _maxCountController,
            onMinChanged: (val) =>
                notifier.updateCapacity(min: int.tryParse(val)),
            onMaxChanged: (val) =>
                notifier.updateCapacity(max: int.tryParse(val)),
          ),
          const SizedBox(height: MinglitSpacing.large),
          PartySectionTitle(context.l10n.partyCreate_label_contact),
          if (partnerInfoAsync.isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
              child: Text(context.l10n.partyCreate_info_loadingPartner),
            ),
          PartyContactInput(
            phoneController: _phoneController,
            emailController: _emailController,
            kakaoController: _kakaoController,
            enabledMethods: state.enabledContactMethods,
            onToggleMethod: notifier.toggleContactMethod,
            onPhoneChanged: notifier.updateContactPhone,
            onEmailChanged: notifier.updateContactEmail,
            onKakaoChanged: notifier.updateContactKakao,
          ),
        ],
      ),
    );
  }
}
