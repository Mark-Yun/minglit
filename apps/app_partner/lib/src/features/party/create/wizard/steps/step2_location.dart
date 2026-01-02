import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/widgets/party_location_detail_input.dart';
import 'package:app_partner/src/features/party/create/widgets/party_location_selector.dart';
import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PartySectionTitle('파티 장소'),
          PartyLocationSelector(
            selectedLocation: state.selectedLocation,
            onSearchTap: _handleLocationSearch,
          ),
          if (state.selectedLocation != null) ...[
            const SizedBox(height: MinglitSpacing.large),
            PartyLocationDetailInput(
              addressDetailController: _addressDetailController,
              directionsController: _directionsController,
              onAddressDetailChanged: notifier.updateAddressDetail,
              onDirectionsChanged: notifier.updateDirections,
            ),
          ],
        ],
      ),
    );
  }
}
