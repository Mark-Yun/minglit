import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/ticket/widgets/party_tickets_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_capacity_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_location_summary.dart';
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
    final colorScheme = theme.colorScheme;
    final errors = notifier.validationErrors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.wizard_review_title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // Validation Warnings
          if (errors.isNotEmpty) _buildErrorCard(context, errors),

          // 1. Basic Info Section
          _buildSection(
            context,
            title: context.l10n.wizard_review_basicInfo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: MinglitSpacing.medium,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(MinglitRadius.card),
                      child: MinglitImage(
                        assetPath: state.imageFile!.path,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  state.title.isEmpty ? '(제목 없음)' : state.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: state.title.isEmpty ? colorScheme.error : null,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  context.l10n.wizard_review_descriptionDone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 2. Location Summary (Reused)
          PartyLocationSummary(
            location: state.selectedLocation,
            addressDetail: state.addressDetail,
            directionsGuide: state.directionsGuide,
            showError: true,
          ),

          const SizedBox(height: MinglitSpacing.large),

          // 3. Capacity & Contact Summary (Reused)
          Text(
            context.l10n.wizard_review_capacityContact,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
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
            showError: true,
          ),

          const SizedBox(height: MinglitSpacing.large),

          // 4. Tickets Summary (Reused)
          Text(
            context.l10n.wizard_review_tickets,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          PartyTicketsSummary(
            tickets: state.tickets,
            entryGroups: state.entryGroups,
            maxCapacity: state.maxParticipants,
            showStats: false,
            showError: true,
          ),

          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, List<String> errors) {
    final colorScheme = Theme.of(context).colorScheme;
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
              Icon(Icons.error_outline, color: colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                context.l10n.wizard_review_warningTitle,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (err) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 26),
              child: Text(
                '• $err',
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.xlarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          child,
        ],
      ),
    );
  }
}
