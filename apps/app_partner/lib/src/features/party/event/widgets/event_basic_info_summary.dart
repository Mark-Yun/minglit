import 'package:app_partner/src/features/party/widgets/party_basic_info_summary.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventBasicInfoSummary extends StatelessWidget {
  const EventBasicInfoSummary({
    required this.event,
    this.showTitle = true,
    this.showFullDescription = false,
    super.key,
  });

  final Event event;
  final bool showTitle;
  final bool showFullDescription;

  @override
  Widget build(BuildContext context) {
    // Aggregation: Use PartyBasicInfoSummary internally
    return PartyBasicInfoSummary(
      title: event.title ?? event.party?.title ?? '',
      description: event.description ?? event.party?.description ?? {},
      imageUrl:
          event.party?.imageUrl, // Currently image is managed at party level
      showTitle: showTitle,
      showFullDescription: showFullDescription,
    );
  }
}
