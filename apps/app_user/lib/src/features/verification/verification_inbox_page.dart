import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'verification_page.dart';

class VerificationInboxPage extends StatefulWidget {
  const VerificationInboxPage({super.key});

  @override
  State<VerificationInboxPage> createState() => _VerificationInboxPageState();
}

class _VerificationInboxPageState extends State<VerificationInboxPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _correctionRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<VerificationRepository>();
      // 보완이 필요한 요청들만 가져옴
      final requests = await repository.getRequestsByStatus(VerificationStatus.needsCorrection);
      setState(() {
        _correctionRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Load inbox error', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('인증 알림함')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _correctionRequests.isEmpty
                ? _buildEmptyView()
                : _buildListView(),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('확인할 알림이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _correctionRequests.length,
      itemBuilder: (context, index) {
        final req = _correctionRequests[index];
        final partner = req['partner'] as Map<String, dynamic>;
        final verification = req['verification'] as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.edit_document, color: Colors.white, size: 20),
            ),
            title: Text(
              '${partner['name']} 파트너',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${verification['title']} 보완 요청이 왔습니다.'),
                Text(
                  '이유: ${req['rejection_reason'] ?? '상세 사유 없음'}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationManagementPage(
                    partnerId: partner['id'],
                    requiredVerificationIds: [verification['id']], 
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}