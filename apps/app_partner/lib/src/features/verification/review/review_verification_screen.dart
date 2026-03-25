import 'dart:async';

import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Verification Review Page**
class ReviewVerificationScreen extends ConsumerStatefulWidget {
  const ReviewVerificationScreen({super.key});

  @override
  ConsumerState<ReviewVerificationScreen> createState() =>
      _ReviewVerificationScreenState();
}

class _ReviewVerificationScreenState
    extends ConsumerState<ReviewVerificationScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadRequests());
    });
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final myPartners = await ref
          .read(partnerRepositoryProvider)
          .getMyManagedPartners();
      if (myPartners.isEmpty) {
        if (!mounted) return;
        setState(() => _pendingRequests = []);
        return;
      }
      final partnerId = myPartners.first.id;
      final reqs = await ref
          .read(verificationRepositoryProvider)
          .getPendingRequests(partnerId);
      if (!mounted) return;
      setState(() => _pendingRequests = reqs);
    } on Object catch (e, st) {
      if (!mounted) return;
      handleMinglitError(context, e, st);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 심사 처리
  Future<void> _reviewRequest(
    String id,
    VerificationStatus status, {
    String? comment,
  }) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      // Fix #309: review + comment in single EF call
      await ref
          .read(verificationRepositoryProvider)
          .reviewRequest(
            submissionId: id,
            status: status,
            comment: comment,
          );

      if (!mounted) return;
      context.showMinglitSuccess(
        context.l10n.reviewVerification_message_processComplete,
      );
      unawaited(_loadRequests());
    } on Object catch (e, st) {
      if (!mounted) return;
      handleMinglitError(context, e, st);
    } finally {
      loading.hide();
    }
  }

  Future<void> _showCorrectionDialog(String submissionId) async {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();

    await MinglitDialog.show<void>(
      context: context,
      title: context.l10n.reviewVerification_dialog_correction_title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText:
                  context.l10n.reviewVerification_dialog_correction_reasonLabel,
              hintText:
                  context.l10n.reviewVerification_dialog_correction_reasonHint,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context
                  .l10n
                  .reviewVerification_dialog_correction_commentLabel,
              hintText:
                  context.l10n.reviewVerification_dialog_correction_commentHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_button_cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Fix #301: needsCorrection removed — use rejected with comment
            unawaited(
              _reviewRequest(
                submissionId,
                VerificationStatus.rejected,
                comment: commentController.text.isNotEmpty
                    ? '${reasonController.text}\n${commentController.text}'
                    : reasonController.text,
              ),
            );
          },
          child: Text(context.l10n.reviewVerification_dialog_correction_send),
        ),
      ],
    );
  }

  Future<void> _showCommentsModal(String submissionId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MinglitRadius.card),
        ),
      ),
      builder: (context) => _CommentsView(submissionId: submissionId),
    );
  }

  Future<void> _showImageDialog(String path) async {
    try {
      // Fix #404: Use repository instead of direct Supabase access
      final signedUrl = await ref
          .read(verificationRepositoryProvider)
          .getVerificationProofSignedUrl(path);
      if (!mounted) return;
      await showDialog<void>(
        // Keep custom dialog for image viewer
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: InteractiveViewer(
            child: Image.network(signedUrl, fit: BoxFit.contain),
          ),
        ),
      );
    } on Exception catch (e) {
      Log.e('Image load error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.reviewVerification_title_pending,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const MinglitCircularProgressIndicator();
    }
    if (_pendingRequests.isEmpty) {
      return Center(child: Text(context.l10n.reviewVerification_message_empty));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) =>
          _buildRequestCard(_pendingRequests[index]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final theme = Theme.of(context);
    final user = req['user'] as Map<String, dynamic>? ?? {};
    // Fix #301: snapshot_data is now an array of history entries
    final snapshotRaw = req['snapshot_data'];
    final snapshotList = snapshotRaw is List ? snapshotRaw : <dynamic>[];
    final lastEntry = snapshotList.isNotEmpty
        ? snapshotList.last as Map<String, dynamic>
        : <String, dynamic>{};
    final claim = lastEntry['data'] as Map<String, dynamic>? ?? {};
    final images = claim.values
        .whereType<String>()
        .where((val) => val.contains('/'))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Chip(label: Text('VERIFICATION')),
                Text(
                  (user['email'] as String?) ?? 'Unknown User',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.small),
            ...claim.entries
                .where(
                  (e) =>
                      e.value is! String || !e.value.toString().contains('/'),
                )
                .map(
                  (e) => Text(
                    '${e.key}: ${e.value}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            const SizedBox(height: MinglitSpacing.medium),
            if (images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => unawaited(_showImageDialog(images[i])),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(
                        right: MinglitSpacing.small,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          MinglitRadius.small,
                        ),
                      ),
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: MinglitSpacing.large),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        unawaited(_showCorrectionDialog(req['id'] as String)),
                    child: Text(
                      context.l10n.reviewVerification_button_correction,
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => unawaited(
                      _reviewRequest(
                        req['id'] as String,
                        VerificationStatus.approved,
                      ),
                    ),
                    child: Text(context.l10n.reviewVerification_button_approve),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () =>
                    unawaited(_showCommentsModal(req['id'] as String)),
                child: Text(
                  context.l10n.reviewVerification_button_chat,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsView extends ConsumerWidget {
  const _CommentsView({required this.submissionId});
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.read(verificationRepositoryProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        children: [
          Text(
            context.l10n.reviewVerification_chat_title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.getVerificationComments(submissionId),
              builder: (context, snapshot) {
                // Fix #382: snapshot.data null 안전성 확보 — hasData가 true여도 data가 null일 수 있음
                final comments = snapshot.data;
                if (comments == null) {
                  return const MinglitCircularProgressIndicator();
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    // Fix #404: Use currentUserProvider instead of direct Supabase auth access
                    final isPartner =
                        comments[i]['author_id'] ==
                        ref.read(currentUserProvider)?.id;
                    final content =
                        comments[i]['content'] as Map<String, dynamic>;
                    final text = content['text'] as String? ?? '';

                    return Align(
                      alignment: isPartner
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: MinglitSpacing.xxsmall,
                        ),
                        padding: const EdgeInsets.all(MinglitSpacing.small),
                        decoration: BoxDecoration(
                          color: isPartner
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            MinglitRadius.small,
                          ),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
