import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/widgets/party_location_detail_input.dart';
import 'package:app_partner/src/features/party/widgets/party_location_input.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyLocationEditScreen extends ConsumerStatefulWidget {
  const PartyLocationEditScreen({
    required this.initialLocation,
    required this.initialAddressDetail,
    required this.initialDirectionsGuide,
    required this.onSave,
    super.key,
  });

  final Location? initialLocation;
  final String? initialAddressDetail;
  final String? initialDirectionsGuide;
  final void Function(Location? location, String detail, String directions)
      onSave;

  @override
  ConsumerState<PartyLocationEditScreen> createState() =>
      _PartyLocationEditScreenState();
}

class _PartyLocationEditScreenState
    extends ConsumerState<PartyLocationEditScreen> {
  Location? _selectedLocation;
  late final TextEditingController _addressDetailController;
  late final TextEditingController _directionsController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _addressDetailController = TextEditingController(
      text: widget.initialAddressDetail,
    );
    _directionsController = TextEditingController(
      text: widget.initialDirectionsGuide,
    );
  }

  @override
  void dispose() {
    _addressDetailController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '${context.l10n.partyCreate_label_location} 수정',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          children: [
            PartyLocationInput(
              selectedLocation: _selectedLocation,
              onSearchTap: () async {
                final loc = await ref
                    .read(partyDetailCoordinatorProvider)
                    .goToLocationSearch(context);
                if (loc != null) {
                  setState(() => _selectedLocation = loc);
                }
              },
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            PartyLocationDetailInput(
              addressDetailController: _addressDetailController,
              directionsController: _directionsController,
              enabled: _selectedLocation != null,
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _selectedLocation,
                  _addressDetailController.text,
                  _directionsController.text,
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
