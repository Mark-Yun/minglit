import 'package:flutter/material.dart';
import '../models/partner.dart';

class PartnerDetailView extends StatelessWidget {
  final Partner partner;

  const PartnerDetailView({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 브랜드 헤더
          _buildHeader(context),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. 소개글
                const Text('파트너 소개', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  partner.introduction ?? '등록된 소개글이 없습니다.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                ),
                
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 24),
                
                // 3. 사업자 정보 (신뢰도 향상 섹션)
                _buildBizInfoSection(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (partner.profileImageUrl != null)
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(partner.profileImageUrl!))
          else
            const CircleAvatar(radius: 50, child: Icon(Icons.store, size: 50)),
          const SizedBox(height: 16),
          Text(
            partner.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (partner.address != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(partner.address!, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBizInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('사업자 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildInfoRow('사업자명', partner.bizName),
          _buildInfoRow('대표자', partner.representativeName),
          _buildInfoRow('사업자번호', partner.bizNumber),
          _buildInfoRow('연락처', partner.contactPhone),
          _buildInfoRow('이메일', partner.contactEmail),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
