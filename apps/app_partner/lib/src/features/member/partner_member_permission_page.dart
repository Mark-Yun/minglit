import 'dart:async';

import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_member_permission_page.g.dart';

/// **Local Provider: Single Partner Member**
///
/// Fetches details for a specific member.
/// Filters from full list, can be updated to fetch from DB.
@riverpod
Future<Map<String, dynamic>?> partnerMember(
  Ref ref, {
  required String partnerId,
  required String targetUserId,
}) async {
  final repository = ref.read(partnerRepositoryProvider);
  final members = await repository.getPartnerMembers(partnerId);

  return members.firstWhereOrNull((m) => m['user_id'] == targetUserId);
}

/// **Partner Member Permission Page**
///
/// Allows editing the Role and Permissions of a specific member.
///
/// **Architecture Pattern:**
/// - **Fetch**: Uses [partnerMemberProvider] to load initial data.
/// - **Mutate**: Uses `_save()` to call Repository directly.
/// - **Sync**: Invalidates both providers on success.
class PartnerMemberPermissionPage extends ConsumerWidget {
  const PartnerMemberPermissionPage({
    required this.partnerId,
    required this.targetUserId,
    super.key,
  });

  final String partnerId;
  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(
      partnerMemberProvider(partnerId: partnerId, targetUserId: targetUserId),
    );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.memberPermission_title,
      ),
      body: MinglitAsyncValueWidget(
        value: memberAsync,
        data: (memberData) {
          if (memberData == null) {
            return Center(
              child: Text(context.l10n.memberPermission_message_notFound),
            );
          }
          return _MemberPermissionForm(
            partnerId: partnerId,
            memberData: memberData,
          );
        },
      ),
    );
  }
}

class _MemberPermissionForm extends ConsumerStatefulWidget {
  const _MemberPermissionForm({
    required this.partnerId,
    required this.memberData,
  });

  final String partnerId;
  final Map<String, dynamic> memberData;

  @override
  ConsumerState<_MemberPermissionForm> createState() =>
      _MemberPermissionFormState();
}

class _MemberPermissionFormState extends ConsumerState<_MemberPermissionForm> {
  late String _selectedRole;
  late List<String> _currentPermissions;
  bool _isSaving = false;

  late final Map<String, String> _permissionLabels;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _permissionLabels = {
      'PARTNER_EDIT': context.l10n.permission_PARTNER_EDIT,
      'SETTLEMENT_VIEW': context.l10n.permission_SETTLEMENT_VIEW,
      'SETTLEMENT_EDIT': context.l10n.permission_SETTLEMENT_EDIT,
      'MEMBER_MANAGE': context.l10n.permission_MEMBER_MANAGE,
      'PARTY_MANAGE': context.l10n.permission_PARTY_MANAGE,
      'VERIFY_LIST_VIEW': context.l10n.permission_VERIFY_LIST_VIEW,
      'USER_DATA_VIEW': context.l10n.permission_USER_DATA_VIEW,
      'VERIFY_REVIEW': context.l10n.permission_VERIFY_REVIEW,
      'COMMENT_MANAGE': context.l10n.permission_COMMENT_MANAGE,
    };
  }

  @override
  void initState() {
    super.initState();
    // Fix #270: dynamic map에서 안전 캐스팅 — null이면 기본값 사용
    _selectedRole = widget.memberData['role'] as String? ?? 'member';
    _currentPermissions = List<String>.from(
      widget.memberData['permissions'] as Iterable<dynamic>? ?? [],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(partnerRepositoryProvider);
      // Fix #270: dynamic map에서 안전 캐스팅
      final userId = widget.memberData['user_id'] as String?;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 확인할 수 없습니다')),
          );
        }
        return;
      }

      await repository.updateMemberRole(
        partnerId: widget.partnerId,
        userId: userId,
        role: _selectedRole,
      );

      await repository.updateMemberPermissions(
        partnerId: widget.partnerId,
        userId: userId,
        permissions: _currentPermissions,
      );

      // Invalidate both list and detail providers to refresh data
      ref
        ..invalidate(partnerMembersProvider(partnerId: widget.partnerId))
        ..invalidate(
          partnerMemberProvider(
            partnerId: widget.partnerId,
            targetUserId: userId,
          ),
        );

      if (mounted) {
        context.showMinglitSuccess(context.l10n.memberPermission_message_saved);
        Navigator.pop(context);
      }
    } on Object catch (e, st) {
      if (mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.memberData['user'] as Map<String, dynamic>? ?? {};

    if (_isSaving) {
      return const MinglitCircularProgressIndicator();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user['name'] as String? ??
                context.l10n.memberPermission_defaultName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user['email'] as String? ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          Text(
            context.l10n.memberPermission_section_role,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          _buildRoleSelector(),
          const SizedBox(height: MinglitSpacing.xlarge),
          Text(
            context.l10n.memberPermission_section_permission,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            context.l10n.memberPermission_message_roleWarning,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          ..._permissionLabels.entries.map(
            (e) => _buildPermissionTile(e.key, e.value),
          ),
          const SizedBox(height: MinglitSpacing.xlarge * 1.5),
          ElevatedButton(
            onPressed: () => unawaited(_save()),
            child: Text(context.l10n.memberPermission_button_save),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.small),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'owner',
              child: Text(context.l10n.memberPermission_role_owner),
            ),
            DropdownMenuItem(
              value: 'manager',
              child: Text(context.l10n.memberPermission_role_manager),
            ),
            DropdownMenuItem(
              value: 'staff',
              child: Text(context.l10n.memberPermission_role_staff),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedRole = v;
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
    final theme = Theme.of(context);
    final isChecked = _currentPermissions.contains(key);
    return CheckboxListTile(
      title: Text(label, style: theme.textTheme.bodyMedium),
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
