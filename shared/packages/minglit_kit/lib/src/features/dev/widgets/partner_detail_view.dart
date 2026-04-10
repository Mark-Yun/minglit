import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:minglit_kit/src/features/social/ui/minglit_social_button.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';
import 'package:minglit_kit/src/ui/widgets/party/event_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_detail_view.g.dart';

/// A detailed view of a Partner profile.
class PartnerDetailView extends ConsumerWidget {
  /// Creates a [PartnerDetailView].
  const PartnerDetailView({required this.partner, super.key});

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
          Row(
            children: [
              if (partner.profileImageUrl != null)
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button,
                  backgroundImage: NetworkImage(partner.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button,
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
          _buildSection(context, '소개', partner.introduction ?? '소개글이 없습니다.'),
          const Divider(height: MinglitSpacing.xlarge * 1.5),
          _buildEventSection(ref, context),
          const Divider(height: MinglitSpacing.xlarge * 1.5),
          _buildSection(context, '사업자 정보', ''),
          _buildInfoRow(context, '상호명', partner.bizName),
          _buildInfoRow(context, '대표자', partner.representativeName),
          _buildInfoRow(context, '사업자번호', partner.bizNumber),
          const SizedBox(height: MinglitSpacing.large),
          _buildSection(context, '연락처', ''),
          _buildInfoRow(context, '이메일', partner.contactEmail),
          _buildInfoRow(context, '전화번호', partner.contactPhone),
        ],
      ),
    );
  }

  Widget _buildEventSection(WidgetRef ref, BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(partnerEventsProvider(partnerId: partner.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '진행 중인 이벤트',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitAsyncValueWidget(
          value: eventsAsync,
          data: (events) {
            if (events.isEmpty) {
              return Text(
                '등록된 이벤트가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            return Column(
              children: [
                for (final event in events) ...[
                  MinglitEventCard(event: event, showPartnerOverlay: false),
                  const SizedBox(height: MinglitSpacing.small),
                ],
              ],
            );
          },
          error: (e, _) => Text('Error: $e'),
        ),
      ],
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

/// Provider to fetch upcoming events for a specific partner.
@riverpod
Future<List<Event>> partnerEvents(Ref ref, {required String partnerId}) {
  return ref.read(partyRepositoryProvider).getEventsByPartnerId(partnerId);
}
