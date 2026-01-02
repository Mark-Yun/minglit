import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_application_detail_page.g.dart';

@riverpod
Future<PartnerApplication?> partnerApplication(
  Ref ref, {
  required String applicationId,
}) async {
  if (applicationId == 'dummy-id') {
    return const PartnerApplication(
      id: 'dummy-id',
      userId: 'dummy-user',
      brandName: '밍글릿 커피 스테이션',
      introduction: '신선한 원두와 프리미엄 분위기의 카페입니다.',
      address: '서울시 강남구 테헤란로 123',
      contactPhone: '010-1234-5678',
      contactEmail: 'coffee@minglit.com',
      bizType: 'cafe',
      bizName: '밍글 커피 주식회사',
      bizNumber: '123-45-67890',
      representativeName: '홍길동',
      bankName: '우리은행',
      accountNumber: '1002-123-456789',
      accountHolder: '홍길동',
      bizRegistrationPath: 'dummy/biz_reg.pdf',
      bankbookPath: 'dummy/bankbook.pdf',
    );
  }

  final apps = await ref
      .read(partnerRepositoryProvider)
      .getAllApplications(status: 'all');

  return apps.cast<PartnerApplication?>().firstWhere(
    (a) => a?.id == applicationId,
    orElse: () => null,
  );
}

class PartnerApplicationDetailPage extends ConsumerStatefulWidget {
  const PartnerApplicationDetailPage({required this.applicationId, super.key});

  final String applicationId;

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
      await ref
          .read(partnerRepositoryProvider)
          .reviewApplication(
            applicationId: widget.applicationId,
            status: status,
            adminComment: comment,
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리되었습니다 ($status)')),
      );
      // Refresh the provider to show updated status
      ref.invalidate(
        partnerApplicationProvider(applicationId: widget.applicationId),
      );
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신청서 상태 변경에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(
      partnerApplicationProvider(applicationId: widget.applicationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('상세 정보')),
      body: appAsync.when(
        data: (app) {
          if (app == null) {
            return const Center(child: Text('신청 정보를 찾을 수 없습니다.'));
          }
          return SingleChildScrollView(
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
                          onPressed: () => unawaited(
                            _processReview(
                              status: 'approved',
                              comment: _commentController.text,
                            ),
                          ),
                          child: const Text('승인'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => unawaited(
                            _processReview(
                              status: 'needs_correction',
                              comment: _commentController.text,
                            ),
                          ),
                          child: const Text('보완 요청'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => unawaited(
                            _processReview(
                              status: 'rejected',
                              comment: _commentController.text,
                            ),
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
          );
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
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
              // TODO(developer): Implement file download logic.
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
