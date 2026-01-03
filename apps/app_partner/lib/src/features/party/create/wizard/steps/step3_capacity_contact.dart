import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/widgets/party_capacity_contact_form.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step3CapacityContact extends ConsumerStatefulWidget {
  const Step3CapacityContact({super.key});

  @override
  ConsumerState<Step3CapacityContact> createState() =>
      _Step3CapacityContactState();
}

class _Step3CapacityContactState extends ConsumerState<Step3CapacityContact> {
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _kakaoController;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(partyCreateWizardControllerProvider);

    _phoneController = TextEditingController(text: state.contactPhone);
    _emailController = TextEditingController(text: state.contactEmail);
    _kakaoController = TextEditingController(text: state.contactKakao ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);

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
          if (!state.enabledContactMethods.contains('phone')) {
            notifier.toggleContactMethod('phone');
          }
        }
        if (partner.contactEmail != null && partner.contactEmail!.isNotEmpty) {
          _emailController.text = partner.contactEmail!;
          notifier.updateContactEmail(partner.contactEmail!);
          if (!state.enabledContactMethods.contains('email')) {
            notifier.toggleContactMethod('email');
          }
        }
        setState(() => _isDataLoaded = true);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: PartyCapacityContactForm(
        minCount: state.minConfirmedCount,
        maxCount: state.maxParticipants,
        phoneController: _phoneController,
        emailController: _emailController,
        kakaoController: _kakaoController,
        enabledMethods: state.enabledContactMethods,
        onMinChanged: (val) => notifier.updateCapacity(min: val),
        onMaxChanged: (val) => notifier.updateCapacity(max: val),
        onToggleMethod: notifier.toggleContactMethod,
        onPhoneChanged: notifier.updateContactPhone,
        onEmailChanged: notifier.updateContactEmail,
        onKakaoChanged: notifier.updateContactKakao,
      ),
    );
  }
}
