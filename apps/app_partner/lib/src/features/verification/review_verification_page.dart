import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewVerificationPage extends StatefulWidget {
  const ReviewVerificationPage({super.key});

  @override
  State<ReviewVerificationPage> createState() => _ReviewVerificationPageState();
}

class _ReviewVerificationPageState extends State<ReviewVerificationPage> {
  @override
  void initState() {
    super.initState();
    // BLoC을 통한 초기 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationBloc>().add(
        const VerificationEvent.loadPendingRequests(),
      );
    });
  }

  /// 심사 처리
  void _reviewRequest(
    String id,
    VerificationStatus status, {
    String? reason,
    String? comment,
  }) {
    context.read<VerificationBloc>().add(
      VerificationEvent.reviewRequest(
        requestId: id,
        status: status,
        rejectionReason: reason,
        comment: comment,
      ),
    );
  }

  Future<void> _showCorrectionDialog(String requestId) async {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();

          await showDialog<void>(      context: context,
      builder:
          (context) => AlertDialog(
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
                  _reviewRequest(
                    requestId,
                    VerificationStatus.needsCorrection,
                    reason: reasonController.text,
                    comment: commentController.text,
                  );
                },
                child: const Text('보완 요청 전송'),
              ),
            ],
          ),
    );
  }

  Future<void> _showCommentsModal(String requestId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsView(requestId: requestId),
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
        builder:
            (context) => Dialog(
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
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('처리가 완료되었습니다.')));
          },
          failure: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('처리 실패: $msg')));
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: state.maybeWhen(
              pendingRequestsLoaded:
                  (reqs) => Text('인증 심사 대기열 (${reqs.length})'),
              orElse: () => const Text('인증 심사 대기열'),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<VerificationBloc>().add(
                const VerificationEvent.loadPendingRequests(),
              );
            },
            child: state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              pendingRequestsLoaded: (requests) {
                if (requests.isEmpty) {
                  return const Center(child: Text('모든 심사가 완료되었습니다! 🎉'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder:
                      (context, index) => _buildRequestCard(requests[index]),
                );
              },
              orElse: () => const Center(child: Text('데이터를 불러오는 중입니다...')),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final user = req['user'] as Map<String, dynamic>? ?? {};
    final claim = req['claim_snapshot'] as Map<String, dynamic>;
    final images = (req['proof_images'] as List?)?.cast<String>() ?? [];

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
                Chip(
                  label: Text((req['category'] as String).toUpperCase()),
                ),
                Text(
                  (user['email'] as String?) ?? 'Unknown User',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...claim.entries.map(
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
                  itemBuilder:
                      (context, i) => GestureDetector(
                        onTap: () => _showImageDialog(images[i]),
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
                    onPressed: () => _showCorrectionDialog(req['id'] as String),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                    child: const Text('보완 요청'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () => _reviewRequest(
                          req['id'] as String,
                          VerificationStatus.approved,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('최종 승인'),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () => _showCommentsModal(req['id'] as String),
                child: const Text('대화 내역 확인', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsView extends StatelessWidget {
  const _CommentsView({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<VerificationRepository>();
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
              future: repository.getVerificationComments(requestId),
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
                      alignment:
                          isPartner
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isPartner ? Colors.orange[100] : Colors.grey[200],
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
