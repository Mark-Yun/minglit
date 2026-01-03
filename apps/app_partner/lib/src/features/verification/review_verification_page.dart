import 'dart:async';

import 'package:app_partner/src/utils/error_handler.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Verification Review Page**
///
/// Allows partners to review pending verification requests from users.
///
/// **Features:**
/// - **Load**: Fetches pending requests via [verificationRepositoryProvider].
/// - **Approve**: Grants verification.
/// - **Reject/Correct**: Sends requests back to the user with a reason.
/// - **Interact**: View images and chat history.
class ReviewVerificationPage extends ConsumerStatefulWidget {
  const ReviewVerificationPage({super.key});

  @override
  ConsumerState<ReviewVerificationPage> createState() =>
      _ReviewVerificationPageState();
}

class _ReviewVerificationPageState
    extends ConsumerState<ReviewVerificationPage> {
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
      final reqs = await ref
          .read(verificationRepositoryProvider)
          .getPendingRequests();
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
    String? reason,
    String? comment,
  }) async {
    try {
      await ref
          .read(verificationRepositoryProvider)
          .reviewRequest(
            submissionId: id,
            status: status,
            adminComment: reason,
          );
      if (comment != null) {
        await ref
            .read(verificationRepositoryProvider)
            .submitComment(
              submissionId: id,
              content: {'text': comment},
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.reviewVerification_message_processComplete,
          ),
        ),
      );
      unawaited(_loadRequests());
    } on Object catch (e, st) {
      if (!mounted) return;
      handleMinglitError(context, e, st);
    }
  }

  Future<void> _showCorrectionDialog(String submissionId) async {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.reviewVerification_dialog_correction_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: context
                    .l10n
                    .reviewVerification_dialog_correction_reasonLabel,
                hintText: context
                    .l10n
                    .reviewVerification_dialog_correction_reasonHint,
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
                hintText: context
                    .l10n
                    .reviewVerification_dialog_correction_commentHint,
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
              unawaited(
                _reviewRequest(
                  submissionId,
                  VerificationStatus.needsCorrection,
                  reason: reasonController.text,
                  comment: commentController.text,
                ),
              );
            },
            child: Text(context.l10n.reviewVerification_dialog_correction_send),
          ),
        ],
      ),
    );
  }

  Future<void> _showCommentsModal(String submissionId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsView(submissionId: submissionId),
    );
  }

  Future<void> _showImageDialog(String path) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('verification-proofs')
          .createSignedUrl(path, 600);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingRequests.isEmpty) {
      return Center(child: Text(context.l10n.reviewVerification_message_empty));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) =>
          _buildRequestCard(_pendingRequests[index]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final user = req['user'] as Map<String, dynamic>? ?? {};
    final claim = req['snapshot_data'] as Map<String, dynamic>? ?? {};
    // Extract proof images from snapshot_data if they exist
    final images = claim.values
        .whereType<String>()
        .where((val) => val.contains('/')) // Simple check for path-like strings
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Chip(label: Text('VERIFICATION')),
                Text(
                  (user['email'] as String?) ?? 'Unknown User',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...claim.entries
                .where(
                  (e) =>
                      e.value is! String || !e.value.toString().contains('/'),
                )
                .map(
                  (e) => Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            const SizedBox(height: 16),

            // 이미지 썸네일
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
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => unawaited(
                      _showCorrectionDialog(req['id'] as String),
                    ),
                    child: Text(
                      context.l10n.reviewVerification_button_correction,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  style: const TextStyle(fontSize: 12),
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
    final repository = ref.read(verificationRepositoryProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            context.l10n.reviewVerification_chat_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.getVerificationComments(submissionId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    final isPartner =
                        comments[i]['author_id'] ==
                        Supabase.instance.client.auth.currentUser?.id;
                    final content =
                        comments[i]['content'] as Map<String, dynamic>;
                    final text = content['text'] as String? ?? '';

                    return Align(
                      alignment: isPartner
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPartner
                              ? Colors.orange[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
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
