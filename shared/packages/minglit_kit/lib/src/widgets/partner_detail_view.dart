import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (partner.profileImageUrl != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(partner.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.store, size: 40, color: Colors.grey),
                ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (partner.address != null)
                      Text(
                        partner.address!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Introduction
          _buildSection('소개', partner.introduction ?? '소개글이 없습니다.'),
          const Divider(height: 48),

          // Parties
          _buildPartySection(ref, context),
          const Divider(height: 48),

          // Business Info
          _buildSection('사업자 정보', ''),
          _buildInfoRow('상호명', partner.bizName),
          _buildInfoRow('대표자', partner.representativeName),
          _buildInfoRow('사업자번호', partner.bizNumber),
          const SizedBox(height: 24),

          // Contact Info
          _buildSection('연락처', ''),
          _buildInfoRow('이메일', partner.contactEmail),
          _buildInfoRow('전화번호', partner.contactPhone),
        ],
      ),
    );
  }

  Widget _buildPartySection(WidgetRef ref, BuildContext context) {
    final partiesAsync = ref.watch(
      partnerPartiesProvider(partnerId: partner.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '진행 중인 파티',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        partiesAsync.when(
          data: (parties) {
            if (parties.isEmpty) {
              return const Text(
                '등록된 파티가 없습니다.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Column(
              children: parties
                  .map((p) => _buildPartyCard(p, context))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildPartyCard(Party party, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
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
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.celebration, color: Colors.orange),
        ),
        title: Text(party.title),
        subtitle: Text(
          (party.contactOptions['phone'] as String?) ?? '문의처 없음',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
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
