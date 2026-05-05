import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dev-only navigation hub for app_user.
/// Accessible at `/dev` in dev flavor only.
class UserDevMap extends StatelessWidget {
  const UserDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Tools')),
      body: ListView(
        children: [
          _DevTile(
            title: 'User Switch',
            subtitle: '/dev/switch',
            onTap: () => context.go('/dev/switch'),
          ),
          _DevTile(
            title: 'Home',
            subtitle: '/',
            onTap: () => context.go('/'),
          ),
          _DevTile(
            title: 'Search',
            subtitle: '/search',
            onTap: () => context.go('/search'),
          ),
          _DevTile(
            title: 'My Page',
            subtitle: '/my',
            onTap: () => context.go('/my'),
          ),
          _DevTile(
            title: 'My Tickets',
            subtitle: '/my/tickets',
            onTap: () => context.go('/my/tickets'),
          ),
          _DevTile(
            title: 'Purchase History',
            subtitle: '/purchase-history',
            onTap: () => context.go('/purchase-history'),
          ),
        ],
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  const _DevTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
