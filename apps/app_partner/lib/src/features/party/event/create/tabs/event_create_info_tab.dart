import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/event/create/event_create_coordinator.dart';
import 'package:app_partner/src/features/party/event/widgets/event_basic_info_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_capacity_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_contact_summary.dart';
import 'package:app_partner/src/features/party/event/widgets/event_location_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreateInfoTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = EventCreateCoordinator(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Basic Info Section
          MinglitEditableSection(
            title: context.l10n.wizard_review_basicInfo,
            onTap: () {
              coordinator.openBasicInfoEdit(
                party: Party(
                  id: '',
                  partnerId: '',
                  title: state.title,
                  description: state.description,
                  // Default for event creation
                  imageUrls: state.imageUrl != null ? [state.imageUrl!] : [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                onSave: (title, desc, imageUrls, newImages, status) {
                  notifier
                    ..updateTitle(title)
                    ..updateDescription(desc);
                },
              );
            },
            child: EventBasicInfoSummary(
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
                  imageUrls: state.imageUrl != null ? [state.imageUrl!] : [],
                ),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Capacity & Contact Section
          MinglitEditableSection(
            title: '인원 및 연락처',
            onTap: () {
              coordinator.openCapacityContactEdit(
                party: Party(
                  id: '',
                  partnerId: '',
                  title: state.title,
                  maxParticipants: state.maxParticipants,
                  contactOptions: state.contactOptions,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                onSave: (min, max, options) {
                  notifier
                    ..updateMaxParticipants(max)
                    ..updateContactOptions(options);
                },
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventCapacitySummary(maxParticipants: state.maxParticipants),
                const SizedBox(height: MinglitSpacing.small),
                EventContactSummary(contactOptions: state.contactOptions),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 3. Location Summary
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_location,
            onTap: () {
              coordinator.openLocationEdit(
                initialLocation: state.selectedLocation,
                initialAddressDetail: state.addressDetail,
                initialDirectionsGuide: state.directionsGuide,
                onSave: (newLoc, detail, directions) {
                  notifier
                    ..updateLocation(newLoc)
                    ..updateAddressDetail(detail)
                    ..updateDirections(directions);
                },
              );
            },
            child: EventLocationSummary(
              location: state.selectedLocation,
              addressDetail: state.addressDetail,
              directionsGuide: state.directionsGuide,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 3. Entrance Conditions
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_entranceCondition,
            onTap: () {}, // Event Entry Groups are read-only for now
            child: PartyEntranceConditionSummary(
              entryGroups: state.entryGroups
                  .map((e) => e.toTemplate())
                  .toList(),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 4. Visibility Setting
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                DropdownButtonFormField<String?>(
                  initialValue: state.visibility,
                  decoration: const InputDecoration(
                    labelText: '공개 설정',
                    prefixIcon: Icon(Icons.visibility),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      child: Text('파티 설정 따라가기'),
                    ),
                    DropdownMenuItem(
                      value: 'public',
                      child: Text('공개'),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Text('비공개'),
                    ),
                  ],
                  onChanged: notifier.setVisibility,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
