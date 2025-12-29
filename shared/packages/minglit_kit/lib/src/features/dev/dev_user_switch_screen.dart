import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'dev_user_switch_screen.g.dart';

/// **Dev User Switch Screen**
///
/// A development-only screen to quickly switch between test users.
/// Fetches users from `user_profiles` table and logs in using
/// the seed password.
class DevUserSwitchScreen extends ConsumerStatefulWidget {
  const DevUserSwitchScreen({super.key});

  @override
  ConsumerState<DevUserSwitchScreen> createState() =>
      _DevUserSwitchScreenState();
}

class _DevUserSwitchScreenState extends ConsumerState<DevUserSwitchScreen> {
  bool _isActionRunning = false;

  Future<void> _switchUser(String email) async {
    setState(() => _isActionRunning = true);
    try {
      // In local dev, all seed users have the same password.
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: email,
            password: 'password',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $email')),
        );
        Navigator.pop(context);
      }
    } on Exception catch (e, st) {
      Log.e('❌ Failed to switch user to $email', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  Future<void> _runSeeder() async {
    setState(() => _isActionRunning = true);
    try {
      if (!DevConfig.isInitialized) {
        throw StateError('DevConfig not initialized. Cannot run seeder.');
      }

      final seeder = DatabaseSeeder(DevConfig.adminClient);
      await seeder.seed();

      // Refresh list
      ref.invalidate(devUserProfilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Seeding Completed!')),
        );
      }
    } on Exception catch (e, st) {
      Log.e('❌ Seeding Failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch user profiles from Supabase
    final usersAsync = ref.watch(devUserProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev: Session Switcher'),
        bottom: _isActionRunning
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devUserProfilesProvider),
          ),
        ],
      ),
      body: usersAsync.when<Widget>(
        data: (List<Map<String, dynamic>> users) {
          if (users.isEmpty) {
            return _buildEmptyState();
          }
          return _buildUserList(users);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace? st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Users Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The database seems empty.\nWould you like to generate seed data?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isActionRunning ? null : _runSeeder,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Run Database Seeder'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final name = user['name'] as String? ?? 'No Name';
        final username = user['username'] as String? ?? '';

        // Infer email based on our seed logic
        var email = '';
        Color? roleColor;
        var roleLabel = 'User';

        if (username.startsWith('owner_')) {
          email = 'owner${username.split('_')[1]}@test.com';
          roleColor = Colors.orange[100];
          roleLabel = 'Owner';
        } else if (username.startsWith('staff_')) {
          // staff_{partnerIdx}_{staffIdx}
          final parts = username.split('_');
          if (parts.length >= 3) {
            email = 'staff${parts[1]}-${parts[2]}@test.com';
            roleLabel = 'Staff (P${parts[1]})';
          }
          roleColor = Colors.blue[100];
        } else if (username.startsWith('user_')) {
          email = 'user${username.split('_')[1]}@test.com';
          roleColor = Colors.grey[100];
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: roleColor,
            child: Text(name.isNotEmpty ? name[0] : '?'),
          ),
          title: Text(name),
          subtitle: Text('$roleLabel • $email'),
          trailing: const Icon(Icons.login),
          onTap: _isActionRunning ? null : () => _switchUser(email),
        );
      },
    );
  }
}

// Internal provider to fetch test users
@riverpod
Future<List<Map<String, dynamic>>> devUserProfiles(Ref ref) async {
  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('user_profiles')
      .select('id, name, username')
      .order('username', ascending: true); // Sort by username
  return List<Map<String, dynamic>>.from(data);
}
