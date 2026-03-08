import 'dart:async';

import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _processReview({required String status, String? comment}) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref
          .read(partnerRepositoryProvider)
          .reviewApplication(
            applicationId: widget.applicationId,
            status: status,
            adminComment: comment,
          );
      if (!mounted) return;

      context.showMinglitSuccess(
        context.l10n.appDetail_message_processed(status),
      );
      ref.invalidate(
        partnerApplicationProvider(applicationId: widget.applicationId),
      );
    } on Object catch (e, st) {
      if (!mounted) return;
      handleMinglitError(context, e, st);
    } finally {
      loading.hide();
    }
  }

  Future<void> _openFile(String path) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      final signedUrl = await ref
          .read(partnerRepositoryProvider)
          .getSignedUrl(path);
      final extension = p.extension(path).toLowerCase();

      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: MinglitColors.textPrimary,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(child: Image.network(signedUrl)),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: MinglitColors.background,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch $signedUrl');
        }
      }
    } on Object catch (e, st) {
      if (mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(
      partnerApplicationProvider(applicationId: widget.applicationId),
    );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: context.l10n.appDetail_title),
      body: MinglitAsyncValueWidget(
        value: appAsync,
        data: (app) {
          if (app == null) {
            return Center(child: Text(context.l10n.appDetail_message_notFound));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context.l10n.appDetail_section_basic),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_brandName,
                  app.brandName ?? '-',
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_bizName,
                  app.bizName ?? '-',
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_repName,
                  app.representativeName ?? '-',
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_bizNumber,
                  app.bizNumber ?? '-',
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_phone,
                  app.contactPhone ?? '-',
                ),
                _buildInfoRow(
                  context.l10n.partnerApplication_field_address,
                  app.address ?? '-',
                ),
                const SizedBox(height: MinglitSpacing.large),
                _buildSectionHeader(context.l10n.appDetail_section_files),
                _buildFileLink(
                  context.l10n.appDetail_label_bizReg,
                  app.bizRegistrationPath,
                ),
                _buildFileLink(
                  context.l10n.appDetail_label_bankbook,
                  app.bankbookPath,
                ),
                const SizedBox(height: MinglitSpacing.large),
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
                  const SizedBox(height: MinglitSpacing.medium),
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
                      const SizedBox(width: MinglitSpacing.medium),
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
                      const SizedBox(width: MinglitSpacing.medium),
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildFileLink(String label, String? path) {
    if (path == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(
              Icons.visibility_outlined,
              size: MinglitIconSize.small,
            ),
            label: Text(context.l10n.appDetail_label_download),
            onPressed: () => unawaited(_openFile(path)),
          ),
        ],
      ),
    );
  }
}
