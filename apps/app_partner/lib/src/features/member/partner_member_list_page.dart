import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerMemberListPage extends StatefulWidget {
  const PartnerMemberListPage({required this.partnerId, super.key});
  final String partnerId;

  @override
  State<PartnerMemberListPage> createState() => _PartnerMemberListPageState();
}

class _PartnerMemberListPageState extends State<PartnerMemberListPage> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final repository = locator<PartnerRepository>();
      final members = await repository.getPartnerMembers(widget.partnerId);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } on Exception catch (e) {
      Log.e('Error loading members', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('직원 및 권한 관리')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final user = member['user'] as Map<String, dynamic>? ?? {};

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        user['name'] as String? ?? '이름 없음',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('역할: ${member['role']}'),
                      trailing: const Icon(Icons.settings, size: 20),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute<bool>(
                            builder:
                                (context) => PartnerMemberPermissionPage(
                                  partnerId: widget.partnerId,
                                  memberData: member,
                                ),
                          ),
                        );
                        if (result ?? false) await _loadMembers();
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO(developer): 멤버 초대 로직 (이메일 검색 등)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('멤버 초대 기능은 준비 중입니다.')));
        },
        label: const Text('직원 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
