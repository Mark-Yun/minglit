import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerApplicationDetailPage extends ConsumerStatefulWidget {
  const PartnerApplicationDetailPage({required this.application, super.key});

  final PartnerApplication application;

  @override
  ConsumerState<PartnerApplicationDetailPage> createState() =>
      _PartnerApplicationDetailPageState();
}

class _PartnerApplicationDetailPageState
    extends ConsumerState<PartnerApplicationDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _processReview({
    required String status,
    String? comment,
  }) async {
    try {
      await ref.read(partnerRepositoryProvider).reviewApplication(
        applicationId: widget.application.id,
        status: status,
        adminComment: comment,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리되었습니다 ($status)')),
      );
      Navigator.pop(context); // Go back to list
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      appBar: AppBar(title: Text('${app.brandName} 상세 정보')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('기본 정보'),
            _buildInfoRow('브랜드명', app.brandName),
            _buildInfoRow('사업자명', app.bizName),
            _buildInfoRow('대표자명', app.representativeName),
            _buildInfoRow('사업자등록번호', app.bizNumber),
            _buildInfoRow('연락처', app.contactPhone),
            _buildInfoRow('주소', app.address),
            const SizedBox(height: 24),
            _buildSectionHeader('첨부 서류'),
            _buildFileLink('사업자등록증', app.bizRegistrationPath),
            _buildFileLink('통장사본', app.bankbookPath),
            const SizedBox(height: 24),
            if (app.status == 'pending') ...[
              _buildSectionHeader('심사 처리'),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: '관리자 코멘트 (선택)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          () => _processReview(
                            status: 'approved',
                            comment: _commentController.text,
                          ),
                      child: const Text('승인'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          () => _processReview(
                            status: 'needs_correction',
                            comment: _commentController.text,
                          ),
                      child: const Text('보완 요청'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          () => _processReview(
                            status: 'rejected',
                            comment: _commentController.text,
                          ),
                      child: const Text('반려'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildSectionHeader('심사 결과'),
              _buildInfoRow('상태', app.status),
              if (app.adminComment != null)
                _buildInfoRow('코멘트', app.adminComment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFileLink(String label, String? path) {
    if (path == null) return const SizedBox.shrink();
    // In a real app, generate a signed URL from Supabase Storage
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 16),
            label: const Text('다운로드/보기'),
            onPressed: () {
              // TODO: Implement file download logic using Supabase Storage
              // final url = Supabase.instance.client.storage.from('partner-proofs').getPublicUrl(path);
              // launchUrl(Uri.parse(url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('파일 다운로드 기능 구현 필요')),
              );
            },
          ),
        ],
      ),
    );
  }
}
