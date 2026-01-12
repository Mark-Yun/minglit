import 'package:app_partner/src/features/party/widgets/party_contact_summary.dart';
import 'package:flutter/material.dart';

class EventContactSummary extends StatelessWidget {
  const EventContactSummary({required this.contactOptions, super.key});

  final Map<String, dynamic> contactOptions;

  @override
  Widget build(BuildContext context) {
    return PartyContactSummary(
      contactOptions: contactOptions,
      enabledContactMethods: Set<String>.from(
        contactOptions.keys.map((k) => k == 'kakao_open_chat' ? 'kakao' : k),
      ),
    );
  }
}
