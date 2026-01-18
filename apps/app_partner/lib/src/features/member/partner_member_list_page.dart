import 'package:app_partner/src/features/member/member_coordinator.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_member_list_page.g.dart';

/// **Local Provider: Partner Members**
@riverpod
Future<List<Map<String, dynamic>>> partnerMembers(
  Ref ref, {
  required String partnerId,
}) async {
  return ref.read(partnerRepositoryProvider).getPartnerMembers(partnerId);
}

/// **Partner Member List Page**
class PartnerMemberListPage extends ConsumerWidget {
  const PartnerMemberListPage({required this.partnerId, super.key});

  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(
      partnerMembersProvider(partnerId: partnerId),
    );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.memberList_title,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showInviteDialog(context),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) => _buildListView(context, ref, members),
        loading: () => const MinglitCircularProgressIndicator(),
        error: (err, stack) => _buildErrorView(context, ref, err),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        label: Text(context.l10n.memberList_button_add),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> members,
  ) {
    final theme = Theme.of(context);
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: MinglitIconSize.xlarge * 2,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              context.l10n.memberList_empty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(partnerMembersProvider(partnerId: partnerId).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
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
    final theme = Theme.of(context);
    final user = member['user'] as Map<String, dynamic>? ?? {};
    final userName = user['name'] as String? ?? 'Unknown';
    final userEmail = user['email'] as String? ?? '';
    final role = member['role'] as String? ?? 'staff';

    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          userName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          context.l10n.memberList_label_roleAndEmail(role, userEmail),
        ),
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

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: MinglitIconSize.xlarge * 1.5,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            context.l10n.memberList_error_load(error.toString()),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(partnerMembersProvider(partnerId: partnerId)),
            child: Text(context.l10n.common_button_retry),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('준비 중입니다.')));
  }
}
