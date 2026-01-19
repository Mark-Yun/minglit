import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/ticket/widgets/party_tickets_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_basic_info_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_location_summary.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step6Review extends ConsumerWidget {
  const Step6Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    final theme = Theme.of(context);
    final errors = notifier.validationErrors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Text(
              context.l10n.wizard_review_title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Validation Warnings
          if (errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: _buildErrorCard(context, errors),
            ),

          // 1. Basic Info Section
          MinglitEditableSection(
            title: context.l10n.wizard_review_basicInfo,
            onTap: () => notifier.setStep(PartyCreateStep.basicInfo),
            child: PartyBasicInfoSummary(
              title: state.title,
              description: state.description,
              imageFile: state.imageFiles.firstOrNull,
              collapsible: true,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Location Summary
          MinglitEditableSection(
            title: context.l10n.wizard_review_location,
            onTap: () => notifier.setStep(PartyCreateStep.location),
            child: PartyLocationSummary(
              location: state.selectedLocation,
              addressDetail: state.addressDetail,
              directionsGuide: state.directionsGuide,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 3. Capacity & Contact Summary
          MinglitEditableSection(
            title: context.l10n.wizard_review_capacityContact,
            onTap: () => notifier.setStep(PartyCreateStep.capacityAndContact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PartyCapacitySummary(
                  minCount: state.minConfirmedCount,
                  maxCount: state.maxParticipants,
                ),
                const SizedBox(height: MinglitSpacing.small),
                PartyContactSummary(
                  contactOptions: {
                    'phone': state.contactPhone,
                    'email': state.contactEmail,
                    'kakao': state.contactKakao,
                  },
                  enabledContactMethods: state.enabledContactMethods,
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 4. Entry Rules
          MinglitEditableSection(
            title: context.l10n.wizard_review_entryRules,
            onTap: () => notifier.setStep(PartyCreateStep.entryRules),
            child: PartyEntranceConditionSummary(
              entryGroups: state.entryGroups,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 5. Tickets Summary
          MinglitEditableSection(
            title: context.l10n.wizard_review_tickets,
            onTap: () => notifier.setStep(PartyCreateStep.tickets),
            child: PartyTicketsSummary(
              tickets: state.tickets.map(Ticket.createFromTemplate).toList(),
              entryGroups: state.entryGroups,
              maxCapacity: state.maxParticipants,
              showStats: false,
            ),
          ),

          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, List<String> errors) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.large),
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: MinglitIconSize.xsmall,
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                context.l10n.wizard_review_warningTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.small),
          ...errors.map(
            (err) => Padding(
              padding: const EdgeInsets.only(
                bottom: MinglitSpacing.xxsmall,
                left: MinglitSpacing.large + MinglitSpacing.xxsmall,
              ),
              child: Text(
                '• $err',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
