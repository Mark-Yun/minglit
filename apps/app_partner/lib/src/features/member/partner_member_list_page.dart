import 'package:app_partner/src/features/member/member_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_member_list_page.g.dart';

/// **Local Provider: Partner Members**
///
/// Fetches the list of members for a specific partner.
/// - **AutoDispose**: Automatically cleans up when the UI is closed.
/// - **Family**: Can be called with different [partnerId]s independently.
@riverpod
Future<List<Map<String, dynamic>>> partnerMembers(
  Ref ref, {
  required String partnerId,
}) async {
  return ref.read(partnerRepositoryProvider).getPartnerMembers(partnerId);
}

/// **Partner Member List Page**
///
/// Displays a list of staff members for a specific partner.
///
/// **Key Features:**
/// - **Declarative UI**: Uses [AsyncValue] to handle Loading/Error/Data states.
/// - **Pull-to-Refresh**: Calls `ref.refresh` on the local provider.
/// - **Navigation**: Delegates to [MemberCoordinator].
class PartnerMemberListPage extends ConsumerWidget {
  const PartnerMemberListPage({required this.partnerId, super.key});

  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider. It automatically handles loading/error states.
    final membersAsync = ref.watch(
      partnerMembersProvider(partnerId: partnerId),
    );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '직원 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              // TODO(mark): Implement Invite Member
            },
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) => _buildListView(context, ref, members),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorView(ref, err),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        label: const Text('직원 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> members,
  ) {
    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('등록된 직원이 없습니다.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(partnerMembersProvider(partnerId: partnerId).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) =>
            _buildMemberCard(context, ref, members[index]),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> member,
  ) {
    final user = member['user'] as Map<String, dynamic>? ?? {};
    final userName = user['name'] as String? ?? '이름 없음';
    final userEmail = user['email'] as String? ?? '';
    final role = member['role'] as String? ?? 'staff';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('역할: $role ($userEmail)'),
        trailing: const Icon(Icons.settings, size: MinglitIconSize.small),
        onTap: () {
          final targetUserId = member['user_id'] as String;
          ref
              .read(memberCoordinatorProvider.notifier)
              .goToMemberPermission(partnerId, targetUserId);
        },
      ),
    );
  }

  Widget _buildErrorView(WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('목록을 불러오지 못했습니다.\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(
              partnerMembersProvider(partnerId: partnerId),
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('멤버 초대 기능은 준비 중입니다.')));
  }
}
