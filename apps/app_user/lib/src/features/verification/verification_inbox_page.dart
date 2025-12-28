import 'dart:async';

import 'package:app_user/src/features/verification/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class VerificationInboxPage extends ConsumerStatefulWidget {
  const VerificationInboxPage({super.key});

  @override
  ConsumerState<VerificationInboxPage> createState() =>
      _VerificationInboxPageState();
}

class _VerificationInboxPageState extends ConsumerState<VerificationInboxPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await ref
          .read(verificationRepositoryProvider)
          .getRequestsByStatus(VerificationStatus.needsCorrection);
      if (mounted) {
        setState(() {
          _requests = requests;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('인증 알림함')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    if (_requests.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: _buildListView(_requests),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '확인할 알림이 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder:
                      (context) => VerificationManagementPage(
                        partnerId: partner['id'] as String,
                        requiredVerificationIds: [verification['id'] as String],
                      ),
                ),
              );
              unawaited(_loadRequests()); // 돌아왔을 때 목록 새로고침
            },
          ),
        );
      },
    );
  }
}
