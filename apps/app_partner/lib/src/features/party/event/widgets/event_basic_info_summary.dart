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
      // Fix #1742: event.title은 nullable — party.title로 폴백 (다른 화면과 일관성 유지)
      title: event.party?.title ?? event.title ?? '',
      description: event.description ?? event.party?.description ?? {},
      imageUrls: event.imageUrls ?? event.party?.imageUrls ?? [],
      showTitle: showTitle,
      showFullDescription: showFullDescription,
    );
  }
}
