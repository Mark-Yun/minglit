import 'dart:async';

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
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('심사 요청 목록을 불러오지 못했습니다.')));
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
      ).showSnackBar(const SnackBar(content: Text('처리가 완료되었습니다.')));
      unawaited(_loadRequests());
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('심사 처리에 실패했습니다. 잠시 후 다시 시도해주세요.'),
        ),
      );
    }
  }

  Future<void> _showCorrectionDialog(String submissionId) async {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보완 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '반려 사유 (요약)',
                hintText: '예: 서류 식별 불가',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '상세 안내 (코멘트)',
                hintText: '유저에게 전달할 자세한 내용을 적어주세요.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
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
            child: const Text('보완 요청 전송'),
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
      appBar: AppBar(
        title: _isLoading
            ? const Text('인증 심사 대기열')
            : Text('인증 심사 대기열 (${_pendingRequests.length})'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('모든 심사가 완료되었습니다! 🎉'));
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
                    child: const Text('보완 요청'),
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
                    child: const Text('최종 승인'),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () =>
                    unawaited(_showCommentsModal(req['id'] as String)),
                child: const Text('대화 내역 확인', style: TextStyle(fontSize: 12)),
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
          const Text(
            '유저와 대화',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
