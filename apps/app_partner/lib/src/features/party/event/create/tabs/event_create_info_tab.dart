import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/event_basic_info_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_capacity_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_contact_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_entrance_condition_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_location_summary.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreateInfoTab extends StatelessWidget {
  const EventCreateInfoTab({
    required this.state,
    required this.notifier,
    required this.partyId,
    super.key,
  });

  final EventCreateState state;
  final EventCreateController notifier;
  final String partyId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Basic Info Section
          _buildSectionHeader(
            context,
            context.l10n.wizard_review_basicInfo,
          ),
          EventBasicInfoSummary(
            event: Event(
              id: '',
              partyId: partyId,
              startTime: state.startTime,
              endTime: state.endTime,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              title: state.title,
              description: state.description,
              party: Party(
                id: partyId,
                partnerId: '',
                title: state.title,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                imageUrl: state.imageUrl,
              ),
            ),
            showFullDescription: true,
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Capacity & Contact Section
          _buildSectionHeader(context, '인원 및 연락처'),
          EventCapacitySummary(
            maxParticipants: state.maxParticipants,
          ),
          const SizedBox(height: MinglitSpacing.small),
          EventContactSummary(
            contactOptions: state.contactOptions,
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 3. Location Summary
          _buildSectionHeader(
            context,
            context.l10n.partyDetail_section_location,
          ),
          EventLocationSummary(
            location: state.selectedLocation,
            addressDetail: state.addressDetail,
            directionsGuide: state.directionsGuide,
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 4. Entrance Conditions Section
          _buildSectionHeader(
            context,
            context.l10n.partyDetail_section_entranceCondition,
          ),
          EventEntranceConditionSummary(
            entryGroups: state.entryGroups,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
