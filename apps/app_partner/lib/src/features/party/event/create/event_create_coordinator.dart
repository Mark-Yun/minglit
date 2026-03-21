import 'dart:async';

import 'package:app_partner/src/features/party/ticket/ui/ticket_template_manage_screen.dart';
import 'package:app_partner/src/features/party/widgets/party_basic_info_edit_screen.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_contact_edit_screen.dart';
import 'package:app_partner/src/features/party/widgets/party_location_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreateCoordinator {
  const EventCreateCoordinator(this.context);

  final BuildContext context;

  void openBasicInfoEdit({
    required Party party,
    required void Function(
      String title,
      Map<String, dynamic> description,
      List<String> imageUrls,
      List<XFile> newImages,
      String status,
    ) onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyBasicInfoEditScreen(
            party: party,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  void openCapacityContactEdit({
    required Party party,
    required void Function(
      int min,
      int max,
      Map<String, String> options,
    ) onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyCapacityContactEditScreen(
            party: party,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  void openLocationEdit({
    required Location? initialLocation,
    required String? initialAddressDetail,
    required String? initialDirectionsGuide,
    required void Function(
      Location? newLoc,
      String addressDetail,
      String directions,
    ) onSave,
  }) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PartyLocationEditScreen(
            initialLocation: initialLocation,
            initialAddressDetail: initialAddressDetail,
            initialDirectionsGuide: initialDirectionsGuide,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  void openTicketTemplateManage(String partyId) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TicketTemplateManageScreen(partyId: partyId),
        ),
      ),
    );
  }
}
