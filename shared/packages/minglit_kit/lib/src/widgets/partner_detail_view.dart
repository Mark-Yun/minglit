import 'package:flutter/material.dart';
import '../../minglit_kit.dart';

class PartnerDetailView extends StatelessWidget {
  final Partner partner;

  const PartnerDetailView({
    super.key,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}