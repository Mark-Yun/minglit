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
      debugPrint('Error loading requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewRequest(String id, VerificationStatus status, [String? reason]) async {
    try {
      final service = locator<VerificationService>();
      await service.reviewRequest(requestId: id, status: status, rejectionReason: reason);
      
      // 목록에서 제거 (즉시 반영)
      setState(() {
        _requests.removeWhere((r) => r['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == VerificationStatus.approved ? '승인되었습니다.' : '반려되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String requestId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반려 사유 입력'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: '반려 사유를 입력하세요 (예: 식별 불가)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reviewRequest(requestId, VerificationStatus.rejected, reasonController.text);
            },
            child: const Text('반려', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 원본 이미지 크게 보기 (Signed URL 생성 후 표시)
  Future<void> _showImageDialog(String path) async {
    try {
      // 1. 보안된 임시 URL 생성 (10분 유효)
      final signedUrl = await Supabase.instance.client.storage
          .from('verification-proofs')
          .createSignedUrl(path, 600);

      if (!mounted) return;

      // 2. 다이얼로그 띄우기
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: Image.network(signedUrl, fit: BoxFit.contain),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('인증 심사 (${_requests.length})')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('대기 중인 요청이 없습니다 🎉'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final user = req['user'] as Map<String, dynamic>? ?? {};
                    final claimData = req['claim_data'] as Map<String, dynamic>;
                    final images = (req['proof_images'] as List).cast<String>();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: 카테고리 & 유저 정보
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(req['category'].toString().toUpperCase()),
                                  backgroundColor: Colors.blue[50],
                                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  user['email'] ?? 'Unknown User',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Body: 요청 내용
                            ...claimData.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(width: 100, child: Text(e.key, style: const TextStyle(color: Colors.grey))),
                                  Expanded(child: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            )),
                            const SizedBox(height: 16),

                            // Images: 증빙 사진
                            if (images.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, imgIndex) {
                                    final path = images[imgIndex];
                                    // Private Bucket이라도 getPublicUrl로 임시 URL 생성 가능 (설정에 따라 다름)
                                    // 여기선 간단히 보여주기 위해 PublicURL 사용하나, 실제론 createSignedUrl 권장
                                    // 편의상 Image.network 사용
                                    return FutureBuilder<String>(
                                      future: Supabase.instance.client.storage
                                          .from('verification-proofs')
                                          .createSignedUrl(path, 3600), // 1시간 유효
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return const SizedBox(width: 100, child: Center(child: CircularProgressIndicator()));
                                        return GestureDetector(
                                          onTap: () => _showImageDialog(path), // 원본 보기 (path 사용 주의 - signedUrl로 변경 필요)
                                          // 다이얼로그용으로는 다시 SignedUrl 따야 하므로 일단 썸네일만
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Footer: 승인/반려 버튼
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showRejectDialog(req['id']),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('반려'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _reviewRequest(req['id'], VerificationStatus.approved),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('승인'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
