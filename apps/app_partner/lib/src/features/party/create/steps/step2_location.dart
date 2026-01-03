import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/widgets/party_location_detail_input.dart';
import 'package:app_partner/src/features/party/widgets/party_location_selector.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step2Location extends ConsumerStatefulWidget {
  const Step2Location({super.key});

  @override
  ConsumerState<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends ConsumerState<Step2Location> {
  late final TextEditingController _addressDetailController;
  late final TextEditingController _directionsController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(partyCreateWizardControllerProvider);
    _addressDetailController = TextEditingController(text: state.addressDetail);
    _directionsController = TextEditingController(text: state.directionsGuide);
  }

  @override
  void dispose() {
    _addressDetailController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  Future<void> _handleLocationSearch() async {
    final coordinator = PartyCreateCoordinator(context);
    final location = await coordinator.goToLocationSearch();
    if (location != null) {
      ref
          .read(partyCreateWizardControllerProvider.notifier)
          .updateLocation(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            onAddressDetailChanged: notifier.updateAddressDetail,
            onDirectionsChanged: notifier.updateDirections,
          ),
        ],
      ),
    );
  }
}
