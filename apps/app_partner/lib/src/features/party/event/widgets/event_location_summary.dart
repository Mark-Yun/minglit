import 'package:app_partner/src/features/party/widgets/party_location_summary.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventLocationSummary extends StatelessWidget {
  const EventLocationSummary({
    this.location,
    this.addressDetail,
    this.directionsGuide,
    super.key,
  });

  final Location? location;
  final String? addressDetail;
  final String? directionsGuide;

  @override
  Widget build(BuildContext context) {
    return PartyLocationSummary(
      location: location,
      addressDetail: addressDetail,
      directionsGuide: directionsGuide,
    );
  }
}
