import 'dart:async';

import 'package:app_partner/src/utils/error_handler.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
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
        SnackBar(
          content: Text(context.l10n.appDetail_message_processed(status)),
        ),
      );
      // Refresh the provider to show updated status
      ref.invalidate(
        partnerApplicationProvider(applicationId: widget.applicationId),
      );
    } on Object catch (e, st) {
      if (!mounted) return;
      handleMinglitError(context, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(
      partnerApplicationProvider(applicationId: widget.applicationId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appDetail_title)),
      body: appAsync.when(
        data: (app) {
          if (app == null) {
            return Center(child: Text(context.l10n.appDetail_message_notFound));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context.l10n.appDetail_section_basic),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_brandName,
                  app.brandName,
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_bizName,
                  app.bizName,
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_repName,
                  app.representativeName,
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_bizNumber,
                  app.bizNumber,
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_phone,
                  app.contactPhone,
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_address,
                  app.address,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context.l10n.appDetail_section_files),
                _buildFileLink(
                  context.l10n.appDetail_label_bizReg,
                  app.bizRegistrationPath,
                ),
                _buildFileLink(
                  context.l10n.appDetail_label_bankbook,
                  app.bankbookPath,
                ),
                const SizedBox(height: 24),
                if (app.status == 'pending') ...[
                  _buildSectionHeader(context.l10n.appDetail_section_review),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: context.l10n.appDetail_label_adminComment,
                      border: const OutlineInputBorder(),
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
                          child: Text(context.l10n.appDetail_button_approve),
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
                          child: Text(context.l10n.appDetail_button_correction),
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
                          child: Text(context.l10n.appDetail_button_reject),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildSectionHeader(context.l10n.appDetail_section_result),
                  _buildInfoRow(
                    context.l10n.appDetail_label_status,
                    app.status,
                  ),
                  if (app.adminComment != null)
                    _buildInfoRow(
                      context.l10n.appDetail_label_comment,
                      app.adminComment!,
                    ),
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
            label: Text(context.l10n.appDetail_label_download),
            onPressed: () {
              // TODO(developer): Implement file download logic.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.appDetail_message_downloadNotImpl),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
