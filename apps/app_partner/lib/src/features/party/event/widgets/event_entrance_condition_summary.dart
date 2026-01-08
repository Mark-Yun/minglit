import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventEntranceConditionSummary extends StatelessWidget {
  const EventEntranceConditionSummary({
    required this.entryGroups,
    super.key,
  });

  final List<PartyEntryGroup> entryGroups;

  @override
  Widget build(BuildContext context) {
    return PartyEntranceConditionSummary(entryGroups: entryGroups);
  }
}
