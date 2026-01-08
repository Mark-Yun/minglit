import 'package:app_partner/src/features/party/widgets/party_capacity_summary.dart';
import 'package:flutter/material.dart';

class EventCapacitySummary extends StatelessWidget {
  const EventCapacitySummary({
    required this.maxParticipants,
    super.key,
  });

  final int maxParticipants;

  @override
  Widget build(BuildContext context) {
    // Aggregation: Reuse PartyCapacitySummary
    // For specific events, we often focus on the max capacity override.
    return PartyCapacitySummary(
      minCount: maxParticipants, // Simulating a fixed count for event view
      maxCount: maxParticipants,
    );
  }
}
