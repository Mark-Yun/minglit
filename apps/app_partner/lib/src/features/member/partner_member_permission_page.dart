import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerMemberPermissionPage extends StatefulWidget {
  const PartnerMemberPermissionPage({
    required this.partnerId,
    required this.memberData,
    super.key,
  });
  final String partnerId;
  final Map<String, dynamic> memberData;

  @override
  State<PartnerMemberPermissionPage> createState() =>
      _PartnerMemberPermissionPageState();
}

class _PartnerMemberPermissionPageState
    extends State<PartnerMemberPermissionPage> {
  late String _selectedRole;
  late List<String> _currentPermissions;
  bool _isSaving = false;

  final Map<String, String> _permissionLabels = {
    'PARTNER_EDIT': '파트너 정보 수정',
    'SETTLEMENT_VIEW': '정산 정보 조회',
    'SETTLEMENT_EDIT': '정산 계좌 수정',
    'MEMBER_MANAGE': '멤버 초대 및 권한 관리',
    'PARTY_MANAGE': '파티 생성 및 관리',
    'VERIFY_LIST_VIEW': '유저 심사 목록 조회',
    'USER_DATA_VIEW': '유저 증빙 서류 열람',
    'VERIFY_REVIEW': '유저 심사 승인/반려',
    'COMMENT_MANAGE': '유저 코멘트 대화',
  };

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.memberData['role'] as String;
    _currentPermissions = List<String>.from(
      widget.memberData['permissions'] as Iterable<dynamic>? ?? [],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repository = locator<PartnerRepository>();
      final userId = widget.memberData['user_id'] as String;

      // 1. 역할 업데이트 (트리거가 권한 자동 동기화)
      await repository.updateMemberRole(
        partnerId: widget.partnerId,
        userId: userId,
        role: _selectedRole,
      );

      // 2. 만약 수동으로 권한을 더 만졌다면 직접 업데이트 (선택 사항)
      await repository.updateMemberPermissions(
        partnerId: widget.partnerId,
        userId: userId,
        permissions: _currentPermissions,
      );

      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.memberData['user'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('권한 상세 설정')),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] as String? ?? '멤버 정보',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user['email'] as String? ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      '역할(Role) 선택',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleSelector(),

                    const SizedBox(height: 32),
                    const Text(
                      '상세 기능 권한(Permissions)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '역할을 변경하면 권한 배열이 기본값으로 초기화됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    ..._permissionLabels.entries.map(
                      (e) => _buildPermissionTile(e.key, e.value),
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '변경 사항 저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'owner', child: Text('Owner (모든 권한)')),
            DropdownMenuItem(
              value: 'manager',
              child: Text('Manager (운영 및 심사)'),
            ),
            DropdownMenuItem(value: 'staff', child: Text('Staff (단순 업무)')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedRole = v;
                // 역할 변경 시 프론트엔드에서도 시각적 피드백을 위해 권한 배열 동기화 (트리거와 동일 로직)
                _syncPermissionsLocally(v);
              });
            }
          },
        ),
      ),
    );
  }

  void _syncPermissionsLocally(String role) {
    if (role == 'owner') {
      _currentPermissions = _permissionLabels.keys.toList();
    } else if (role == 'manager') {
      _currentPermissions = [
        'PARTNER_EDIT',
        'PARTY_MANAGE',
        'VERIFY_LIST_VIEW',
        'USER_DATA_VIEW',
        'VERIFY_REVIEW',
        'COMMENT_MANAGE',
      ];
    } else {
      _currentPermissions = [
        'VERIFY_LIST_VIEW',
        'COMMENT_MANAGE',
        'PARTY_MANAGE',
      ];
    }
  }

  Widget _buildPermissionTile(String key, String label) {
    final isChecked = _currentPermissions.contains(key);
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: isChecked,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) {
        setState(() {
          if (v ?? false) {
            _currentPermissions.add(key);
          } else {
            _currentPermissions.remove(key);
          }
        });
      },
    );
  }
}
