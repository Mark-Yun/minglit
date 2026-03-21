import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/widgets/party_basic_info_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_location_summary.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyDetailInfoTab extends ConsumerWidget {
  const PartyDetailInfoTab({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(party.locationId));
    final coordinator = ref.read(partyDetailCoordinatorProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Basic Info Section
          MinglitEditableSection(
            title: context.l10n.wizard_review_basicInfo,
            onTap: () {
              coordinator.openBasicInfoEdit(
                context,
                party: party,
                onSave: (title, description, imageUrls, newImages, status) =>
                    _handleUpdateBasicInfo(
                  context,
                  ref,
                  title,
                  description,
                  imageUrls,
                  newImages,
                  status,
                ),
              );
            },
            child: PartyBasicInfoSummary(
              title: party.title,
              description: party.description ?? {},
              imageUrls: party.imageUrls,
              status: party.status,
              showFullDescription: true,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Capacity & Contact Section
          MinglitEditableSection(
            title: '인원 및 연락처 설정',
            onTap: () {
              coordinator.openCapacityContactEdit(
                context,
                party: party,
                onSave: (min, max, options) => _handleUpdateCapacityContact(
                  context,
                  ref,
                  min,
                  max,
                  options,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PartyCapacitySummary(
                  minCount: party.minConfirmedCount,
                  maxCount: party.maxParticipants,
                ),
                const SizedBox(height: MinglitSpacing.small),
                PartyContactSummary(
                  contactOptions: party.contactOptions,
                  enabledContactMethods: Set<String>.from(
                    party.contactOptions.keys.map(
                      (k) => k == 'kakao_open_chat' ? 'kakao' : k,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 4. Entrance Conditions
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_entranceCondition,
            onTap: () => _showEntranceConditionsEdit(context, ref, party),
            child: PartyEntranceConditionSummary(
              entryGroups: party.entryGroups ?? [],
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 6. Location Summary
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_location,
            onTap: () {
              final loc = locationAsync.value;
              coordinator.openLocationEdit(
                context,
                initialLocation: loc,
                initialAddressDetail: loc?.addressDetail,
                initialDirectionsGuide: loc?.directionsGuide,
                onSave: (newLoc, detail, directions) => _handleUpdateLocation(
                  context,
                  ref,
                  newLoc,
                  detail,
                  directions,
                ),
              );
            },
            child: MinglitAsyncValueWidget(
              value: locationAsync,
              data: (loc) => PartyLocationSummary(
                location: loc,
                addressDetail: loc?.addressDetail,
                directionsGuide: loc?.directionsGuide,
              ),
              loading: () => const MinglitSkeleton(height: 120),
              error: (e, s) => Text(
                context.l10n.partyDetail_error_locationLoad(e.toString()),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }

  void _showEntranceConditionsEdit(
    BuildContext context,
    WidgetRef ref,
    Party party,
  ) {
    // Current UI doesn't have a specific group to edit,
    // so we navigate to a screen or logic that handles groups.
    // For now, keep the logic of tapping a group if needed,
    // but the section itself is now clickable.
  }

  Future<void> _handleUpdateLocation(
    BuildContext context,
    WidgetRef ref,
    Location? newLocation,
    String addressDetail,
    String directionsGuide,
  ) async {
    if (newLocation == null) return;

    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      final locationRepo = ref.read(locationRepositoryProvider);
      final partyRepo = ref.read(partyRepositoryProvider);

      // Check if coordinates changed (New location vs Current location)
      final currentLocation =
          ref.read(locationDetailProvider(party.locationId)).value;

      final isSameSpot = currentLocation != null &&
          currentLocation.latitude == newLocation.latitude &&
          currentLocation.longitude == newLocation.longitude;

      if (isSameSpot) {
        // Scenario 1: Same spot, update only details
        await locationRepo.updateLocationDetails(
          locationId: currentLocation.id,
          addressDetail: addressDetail,
          directionsGuide: directionsGuide,
        );
        Log.d(
          'Location details updated for existing ID: ${currentLocation.id}',
        );
      } else {
        // Scenario 2: New spot or no previous location, create new record
        final savedLocation = await locationRepo.createLocation(
          newLocation.copyWith(
            partnerId: party.partnerId,
            addressDetail: addressDetail,
            directionsGuide: directionsGuide,
          ),
        );
        // Link new location to party
        await partyRepo.updatePartyLocation(party.id, savedLocation.id);
        Log.d('New location created and linked to party: ${savedLocation.id}');
      }

      // Refresh data
      ref.invalidate(partyDetailProvider(party.id));
      if (party.locationId != null) {
        ref.invalidate(locationDetailProvider(party.locationId));
      }

      if (context.mounted) {
        context.showMinglitSuccess(
          context.l10n.partyDetail_message_locationUpdated,
        );
      }
    } on Exception catch (e, st) {
      Log.e('Failed to update location', e, st);
      if (context.mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      loading.hide();
    }
  }

  Future<void> _handleUpdateBasicInfo(
    BuildContext context,
    WidgetRef ref,
    String title,
    Map<String, dynamic> description,
    List<String> imageUrls,
    List<XFile> newImages,
    String status,
  ) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      final repo = ref.read(partyRepositoryProvider);
      final finalUrls = List<String>.from(imageUrls);

      if (newImages.isNotEmpty) {
        final uploadedUrls = await repo.uploadPartyImages(
          newImages,
          party.partnerId,
        );
        finalUrls.addAll(uploadedUrls);
      }

      await repo.updatePartyBasicInfo(
        partyId: party.id,
        title: title,
        description: description,
        imageUrls: finalUrls,
        status: status,
      );

      ref.invalidate(partyDetailProvider(party.id));

      if (context.mounted) {
        context.showMinglitSuccess('기본 정보가 수정되었습니다.');
      }
    } on Exception catch (e, st) {
      if (context.mounted) handleMinglitError(context, e, st);
    } finally {
      loading.hide();
    }
  }

  Future<void> _handleUpdateCapacityContact(
    BuildContext context,
    WidgetRef ref,
    int minCount,
    int maxCount,
    Map<String, String> contactOptions,
  ) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref
          .read(partyDetailCoordinatorProvider)
          .updatePartyCapacityAndContact(
            partyId: party.id,
            minCount: minCount,
            maxCount: maxCount,
            contactOptions: contactOptions,
            context: context,
          );
      ref.invalidate(partyDetailProvider(party.id));
    } on Exception catch (e, st) {
      if (context.mounted) handleMinglitError(context, e, st);
    } finally {
      loading.hide();
    }
  }
}
