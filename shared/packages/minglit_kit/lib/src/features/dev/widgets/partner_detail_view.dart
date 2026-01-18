import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:minglit_kit/src/features/dev/widgets/party_detail_view.dart';
import 'package:minglit_kit/src/features/social/ui/minglit_social_button.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_detail_view.g.dart';

/// A detailed view of a Partner profile.
class PartnerDetailView extends ConsumerWidget {
  /// Creates a [PartnerDetailView].
  const PartnerDetailView({
    required this.partner,
    super.key,
  });

  /// The partner data to display.
  final Partner partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (partner.profileImageUrl != null)
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button, // 40
                  backgroundImage: NetworkImage(partner.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button, // 40
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.store,
                    size: MinglitIconSize.xlarge * 1.25,
                    color: theme.colorScheme.outline,
                  ),
                ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (partner.address != null)
                      Text(
                        partner.address!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: MinglitSpacing.small),
                    MinglitSocialButton(
                      targetId: partner.id,
                      targetType: SocialTargetType.partner,
                      interactionType: SocialInteractionType.subscribe,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Introduction
          _buildSection(context, '소개', partner.introduction ?? '소개글이 없습니다.'),
          const Divider(height: MinglitSpacing.xlarge * 1.5),

          // Parties
          _buildPartySection(ref, context),
          const Divider(height: MinglitSpacing.xlarge * 1.5),

          // Business Info
          _buildSection(context, '사업자 정보', ''),
          _buildInfoRow(context, '상호명', partner.bizName),
          _buildInfoRow(context, '대표자', partner.representativeName),
          _buildInfoRow(context, '사업자번호', partner.bizNumber),
          const SizedBox(height: MinglitSpacing.large),

          // Contact Info
          _buildSection(context, '연락처', ''),
          _buildInfoRow(context, '이메일', partner.contactEmail),
          _buildInfoRow(context, '전화번호', partner.contactPhone),
        ],
      ),
    );
  }

  Widget _buildPartySection(WidgetRef ref, BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(
      partnerPartiesProvider(partnerId: partner.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '진행 중인 파티',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        partiesAsync.when(
          data: (parties) {
            if (parties.isEmpty) {
              return Text(
                '등록된 파티가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            return Column(
              children: parties
                  .map((p) => _buildPartyCard(p, context))
                  .toList(),
            );
          },
          loading: () => const MinglitCircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildPartyCard(Party party, BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: ListTile(
        onTap: () {
          unawaited(
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => PartyDetailView(party: party),
              ),
            ),
          );
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MinglitRadius.small),
          ),
          child: Icon(Icons.celebration, color: theme.colorScheme.secondary),
        ),
        title: Text(party.title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          (party.contactOptions['phone'] as String?) ?? '문의처 없음',
          style: theme.textTheme.labelSmall,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.small),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xxsmall),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider to fetch parties for a specific partner.
@riverpod
Future<List<Party>> partnerParties(Ref ref, {required String partnerId}) {
  return ref.read(partyRepositoryProvider).getPartiesByPartnerId(partnerId);
}
