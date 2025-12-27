import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerApplicationDetailPage extends StatefulWidget {
  final Map<String, dynamic> application;
  const PartnerApplicationDetailPage({super.key, required this.application});

  @override
  State<PartnerApplicationDetailPage> createState() => _PartnerApplicationDetailPageState();
}

class _PartnerApplicationDetailPageState extends State<PartnerApplicationDetailPage> {
  bool _isProcessing = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _reviewApplication(String status) async {
    setState(() => _isProcessing = true);
    try {
      final repository = locator<PartnerRepository>();
      await repository.reviewApplication(
        applicationId: widget.application['id'],
        status: status,
        adminComment: _commentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리가 완료되었습니다: $status')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleReview(String status) {
    if (status == 'needs_correction' || status == 'rejected') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'rejected' ? '반려 사유 입력' : '보완 요청 사항'),
          content: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '상세 내용을 적어주세요.'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _reviewApplication(status);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      _reviewApplication(status);
    }
  }

  Future<void> _showDocument(String path) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('partner-proofs')
          .createSignedUrl(path, 600);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(child: Image.network(signedUrl)),
        ),
      );
    } catch (e) {
      Log.e('Doc view error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    
    return Scaffold(
      appBar: AppBar(title: const Text('신청 상세 심사')),
      body: _isProcessing 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('브랜드 정보', {
                    '브랜드명': app['brand_name'],
                    '소개': app['introduction'],
                    '주소': app['address'],
                    '연락처': app['contact_phone'],
                    '이메일': app['contact_email'],
                  }),
                  _buildSection('사업자 및 계좌 정보', {
                    '사업자유형': app['biz_type'],
                    '사업자명': app['biz_name'],
                    '사업자번호': app['biz_number'],
                    '대표자': app['representative_name'],
                    '은행': app['bank_name'],
                    '계좌번호': app['account_number'],
                    '예금주': app['account_holder'],
                  }),
                  const SizedBox(height: 24),
                  const Text('증빙 서류 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDocTile('사업자등록증', app['biz_registration_path']),
                  _buildDocTile('통장 사본', app['bankbook_path']),
                  
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleReview('rejected'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('반려'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleReview('needs_correction'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                          child: const Text('보완 요청'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleReview('approved'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('최종 승인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: data.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 100, child: Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  Expanded(child: Text(e.value?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDocTile(String label, String path) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => _showDocument(path),
    );
  }
}