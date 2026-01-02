import 'dart:io';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_basic_condition_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step6Review extends ConsumerWidget {
  const Step6Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      child: kIsWeb
                          ? Image.network(
                              state.imageFile!.path,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(state.imageFile!.path),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                Text(
                  state.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

          // 2. Location Section
          _buildSection(
            context,
            title: context.l10n.wizard_review_location,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        state.selectedLocation?.name ??
                            context.l10n.wizard_review_noLocation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.selectedLocation?.address ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.addressDetail != null &&
                    state.addressDetail!.isNotEmpty)
                  Text(
                    state.addressDetail!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),

          // 3. Capacity & Contact Section
          _buildSection(
            context,
            title: context.l10n.wizard_review_capacityContact,
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  Icons.people_outline,
                  context.l10n.partyCreate_label_capacity,
                  '${state.minConfirmedCount} ~ ${state.maxParticipants}명',
                ),
                if (state.enabledContactMethods.contains('phone'))
                  _buildInfoRow(
                    context,
                    Icons.phone_outlined,
                    '연락처',
                    state.contactPhone,
                  ),
                if (state.enabledContactMethods.contains('email'))
                  _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    '이메일',
                    state.contactEmail,
                  ),
                if (state.enabledContactMethods.contains('kakao'))
                  _buildInfoRow(
                    context,
                    Icons.chat_bubble_outline,
                    '카카오톡',
                    state.contactKakao ?? '-',
                  ),
              ],
            ),
          ),

          // 4. Entry Rules Section
          _buildSection(
            context,
            title: context.l10n.wizard_review_entryRules,
            child: PartyBasicConditionSection(
              party: Party(
                id: '',
                partnerId: '',
                title: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                conditions: state.entryGroups.map((e) => e.toJson()).toList(),
              ),
            ),
          ),

          // 5. Tickets Section
          _buildSection(
            context,
            title: context.l10n.wizard_review_tickets,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.tickets.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MinglitSpacing.small),
              itemBuilder: (context, index) {
                return TicketListItem(
                  ticket: state.tickets[index],
                  entryGroups: state.entryGroups,
                  showStats: false,
                );
              },
            ),
          ),

          const SizedBox(height: MinglitSpacing.xlarge),
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

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
