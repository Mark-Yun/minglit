import 'dart:async';

import 'package:app_user/src/common/widgets/minglit_avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #1929: manual widget state를 Riverpod FutureProvider로 대체해 차단 목록 로딩을 관리
// Fix #1927: autoDispose로 페이지 재진입 시마다 최신 목록을 새로 fetch
final FutureProvider<List<Map<String, dynamic>>> blockedPartnersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((
      ref,
    ) async {
      // Fix #270: 네트워크 실패 시 에러 처리 — 영구 로딩 상태 방지
      try {
        return await ref.watch(socialRepositoryProvider).getBlockedPartners();
      } on Object catch (e, st) {
        // Fix #1927: structured error logging을 위해 debugPrint 대신 Log.e 사용
        Log.e('Failed to load blocked partners', e, st);
        rethrow;
      }
    });

class BlockedPartnersPage extends ConsumerWidget {
  const BlockedPartnersPage({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String partnerId,
  ) async {
    final confirmed = await MinglitAlert.showConfirm(
      context: context,
      title: '차단 해제',
      content: '이 파트너의 차단을 해제하시겠습니까?',
      confirmText: '해제',
    );
    if (!confirmed) return;

    await ref.read(socialRepositoryProvider).unblockPartner(partnerId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('차단이 해제되었습니다')));
    ref.invalidate(blockedPartnersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnersAsync = ref.watch(blockedPartnersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: partnersAsync.when(
        loading: () => const Center(child: MinglitCircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            '차단 목록을 불러오지 못했습니다',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        data: (partners) {
          if (partners.isEmpty) {
            return Center(
              child: Text(
                '차단된 파트너가 없습니다',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final p = partners[index];
              final id = p['id'] as String;
              final name = p['name'] as String? ?? '';
              final imageUrl = p['profile_image_url'] as String?;
              return ListTile(
                // Fix #1936: MinglitAvatarImage handles caching + error fallback
                leading: MinglitAvatarImage(
                  radius: 20,
                  url: imageUrl,
                  fallbackIcon: Icons.store,
                ),
                title: Text(name),
                trailing: TextButton(
                  onPressed: () => unawaited(_unblock(context, ref, id)),
                  child: const Text('차단 해제'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
