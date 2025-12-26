import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewVerificationPage extends StatefulWidget {
  const ReviewVerificationPage({super.key});

  @override
  State<ReviewVerificationPage> createState() => _ReviewVerificationPageState();
}

class _ReviewVerificationPageState extends State<ReviewVerificationPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final service = locator<VerificationService>();
      final requests = await service.getPendingRequests();
      setState(() => _requests = requests);
    } catch (e) {
      Log.e('Error loading requests', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 심사 처리 (승인/반려/보완요청)
  Future<void> _reviewRequest(String id, VerificationStatus status, {String? reason, String? comment}) async {
    try {
      final service = locator<VerificationService>();
      
      // 1. 상태 업데이트
      await service.reviewRequest(requestId: id, status: status, rejectionReason: reason);
      
      // 2. 코멘트가 있다면 추가
      if (comment != null && comment.isNotEmpty) {
        await service.submitComment(requestId: id, content: {'text': comment});
      }
      
      // 목록 새로고침 (간단하게 처리)
      _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리가 완료되었습니다: ${status.value}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
      }
    }
  }

  /// 보완 요청 다이얼로그
  void _showCorrectionDialog(String requestId) {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보완 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '반려 사유 (요약)', hintText: '예: 서류 식별 불가'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '상세 안내 (코멘트)', hintText: '유저에게 전달할 자세한 내용을 적어주세요.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewRequest(requestId, VerificationStatus.needs_correction, 
                reason: reasonController.text, comment: commentController.text);
            },
            child: const Text('보완 요청 전송'),
          ),
        ],
      ),
    );
  }

  /// 대화 내역 모달 (유저 앱과 동일한 컴포넌트 사용 권장하나 일단 내부에 구현)
  void _showCommentsModal(String requestId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CommentsView(requestId: requestId),
    );
  }

  Future<void> _showImageDialog(String path) async {
    try {
      final signedUrl = await Supabase.instance.client.storage.from('verification-proofs').createSignedUrl(path, 600);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(child: Image.network(signedUrl, fit: BoxFit.contain)),
        ),
      );
    } catch (e) {
      Log.e('Image load error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('인증 심사 대기열 (${_requests.length})')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? const Center(child: Text('모든 심사가 완료되었습니다! 🎉'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                  ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final user = req['user'] as Map<String, dynamic>? ?? {};
    final claim = req['claim_snapshot'] as Map<String, dynamic>;
    final images = (req['proof_images'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(req['category'].toString().toUpperCase())),
                Text(user['email'] ?? 'Unknown User', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            ...claim.entries.map((e) => Text('${e.key}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            
            // 이미지 썸네일
            if (images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _showImageDialog(images[i]),
                    child: Container(
                      width: 80, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.image), // 실제론 여기서도 SignedUrl 썸네일 표시 권장
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCorrectionDialog(req['id']),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('보완 요청'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reviewRequest(req['id'], VerificationStatus.approved),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('최종 승인'),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () => _showCommentsModal(req['id']),
                child: const Text('대화 내역 확인', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 심사 대화 내역 뷰 (모달용)
class _CommentsView extends StatelessWidget {
  final String requestId;
  const _CommentsView({required this.requestId});

  @override
  Widget build(BuildContext context) {
    final service = locator<VerificationService>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('유저와 대화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: service.getVerificationComments(requestId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    final isPartner = comments[i]['author_id'] == Supabase.instance.client.auth.currentUser?.id;
                    return Align(
                      alignment: isPartner ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPartner ? Colors.orange[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(comments[i]['content']['text'] ?? ''),
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