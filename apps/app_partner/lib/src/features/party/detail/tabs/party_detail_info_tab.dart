import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/widgets/party_basic_info_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_input.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_location_summary.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
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
            onTap: () => coordinator.goToEditParty(party.id),
            child: PartyBasicInfoSummary(
              title: party.title,
              description: party.description ?? {},
              imageUrl: party.imageUrl,
              showFullDescription: true,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Capacity & Contact Section
          MinglitEditableSection(
            title: '인원 및 연락처 설정',
            onTap: () => _showCapacityContactEditSheet(context, ref, party),
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

          // 3. Entrance Conditions
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_entranceCondition,
            onTap: () => _showEntranceConditionsEdit(context, ref, party),
            child: PartyEntranceConditionSummary(
              entryGroups: party.entryGroups,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 4. Location Summary
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_location,
            onTap: () => _handleEditLocation(context, ref),
            child: locationAsync.when(
              data: (loc) => PartyLocationSummary(
                location: loc,
                addressDetail: loc?.addressDetail,
                directionsGuide: loc?.directionsGuide,
                onEditDetail: loc != null
                    ? () => _showLocationDetailEditSheet(context, ref, loc)
                    : null,
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

  Future<void> _handleEditLocation(BuildContext context, WidgetRef ref) async {
    final coordinator = ref.read(partyDetailCoordinatorProvider);
    final newLocation = await coordinator.goToLocationSearch(context);
    if (newLocation != null) {
      final loading = ref.read(globalLoadingControllerProvider.notifier)
        ..show();
      try {
        final locationRepo = ref.read(locationRepositoryProvider);
        final savedLocation = await locationRepo.createLocation(
          newLocation.copyWith(partnerId: party.partnerId),
        );

        final partyRepo = ref.read(partyRepositoryProvider);
        await partyRepo.updatePartyLocation(party.id, savedLocation.id);

        ref.invalidate(partyDetailProvider(party.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.partyDetail_message_locationUpdated),
            ),
          );
        }
      } on Exception catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.common_error_system)),
          );
        }
      } finally {
        loading.hide();
      }
    }
  }

  void _showCapacityContactEditSheet(
    BuildContext context,
    WidgetRef ref,
    Party party,
  ) {
    final phoneController = TextEditingController(
      text: party.contactOptions['phone'] as String?,
    );
    final emailController = TextEditingController(
      text: party.contactOptions['email'] as String?,
    );
    final kakaoController = TextEditingController(
      text: party.contactOptions['kakao_open_chat'] as String?,
    );
    var minCount = party.minConfirmedCount;
    var maxCount = party.maxParticipants;
    final enabledMethods = Set<String>.from(
      party.contactOptions.keys.map((k) {
        if (k == 'kakao_open_chat') return 'kakao';
        return k;
      }),
    );

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MinglitSpacing.large),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '인원 및 연락처 수정',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: MinglitSpacing.large),
                      Text(
                        context.l10n.partyCreate_label_capacity,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                      PartyCapacityInput(
                        minCount: minCount,
                        maxCount: maxCount,
                        onMinChanged: (val) => setState(() => minCount = val),
                        onMaxChanged: (val) => setState(() => maxCount = val),
                      ),
                      const SizedBox(height: MinglitSpacing.large),
                      Text(
                        context.l10n.partyCreate_label_contact,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                      PartyContactInput(
                        phoneController: phoneController,
                        emailController: emailController,
                        kakaoController: kakaoController,
                        enabledMethods: enabledMethods,
                        onToggleMethod: (method) {
                          setState(() {
                            if (enabledMethods.contains(method)) {
                              enabledMethods.remove(method);
                            } else {
                              enabledMethods.add(method);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: MinglitSpacing.xlarge),
                      ElevatedButton(
                        onPressed: () async {
                          final options = <String, String>{};
                          if (enabledMethods.contains('phone')) {
                            options['phone'] = phoneController.text;
                          }
                          if (enabledMethods.contains('email')) {
                            options['email'] = emailController.text;
                          }
                          if (enabledMethods.contains('kakao')) {
                            options['kakao_open_chat'] = kakaoController.text;
                          }

                          await ref
                              .read(partyDetailCoordinatorProvider)
                              .updatePartyCapacityAndContact(
                                partyId: party.id,
                                minCount: minCount,
                                maxCount: maxCount,
                                contactOptions: options,
                                context: context,
                              );
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(context.l10n.common_button_save),
                      ),
                      const SizedBox(height: MinglitSpacing.large),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLocationDetailEditSheet(
    BuildContext context,
    WidgetRef ref,
    Location loc,
  ) {
    final detailController = TextEditingController(text: loc.addressDetail);
    final guideController = TextEditingController(text: loc.directionsGuide);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${context.l10n.partyCreate_label_location} '
                    '${context.l10n.common_button_edit}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                  TextFormField(
                    controller: detailController,
                    decoration: InputDecoration(
                      labelText: context.l10n.partyCreate_label_addressDetail,
                      hintText: context.l10n.partyCreate_hint_addressDetail,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  TextFormField(
                    controller: guideController,
                    decoration: InputDecoration(
                      labelText: context.l10n.partyCreate_label_directions,
                      hintText: context.l10n.partyCreate_hint_directions,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: MinglitSpacing.xlarge),
                  ElevatedButton(
                    onPressed: () {
                      unawaited(
                        () async {
                          try {
                            final repo = ref.read(locationRepositoryProvider);
                            await repo.updateLocationDetails(
                              locationId: loc.id,
                              addressDetail: detailController.text,
                              directionsGuide: guideController.text,
                            );
                            ref.invalidate(locationDetailProvider(loc.id));
                            if (context.mounted) {
                              Navigator.pop(context);
                              final msg = context
                                  .l10n
                                  .partyDetail_message_locationDetailUpdated;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          } on Exception catch (e) {
                            debugPrint('Update failed: $e');
                          }
                        }(),
                      );
                    },
                    child: Text(context.l10n.common_button_save),
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
