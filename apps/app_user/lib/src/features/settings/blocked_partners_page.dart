import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class BlockedPartnersPage extends ConsumerStatefulWidget {
  const BlockedPartnersPage({super.key});

  @override
  ConsumerState<BlockedPartnersPage> createState() =>
      _BlockedPartnersPageState();
}

class _BlockedPartnersPageState extends ConsumerState<BlockedPartnersPage> {
  List<Map<String, dynamic>>? _partners;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ref.read(socialRepositoryProvider).getBlockedPartners();
    if (mounted) {
      setState(() {
        _partners = data;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(String partnerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단 해제'),
        content: const Text('이 파트너의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(socialRepositoryProvider).unblockPartner(partnerId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단이 해제되었습니다')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _partners == null || _partners!.isEmpty
          ? Center(
              child: Text(
                '차단된 파트너가 없습니다',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _partners!.length,
              itemBuilder: (context, index) {
                final p = _partners![index];
                final id = p['id'] as String;
                final name = p['name'] as String? ?? '';
                final imageUrl = p['profile_image_url'] as String?;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null ? const Icon(Icons.store) : null,
                  ),
                  title: Text(name),
                  trailing: TextButton(
                    onPressed: () => _unblock(id),
                    child: const Text('차단 해제'),
                  ),
                );
              },
            ),
    );
  }
}
