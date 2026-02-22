import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'dev_user_switch_screen.g.dart';

/// **Dev User Switch Screen**
///
/// A development-only screen to quickly switch between test users.
/// Fetches users from `user_profiles` table and logs in using
/// the seed password.
///
/// Note: Seeding functionality has been removed from the UI.
/// Use `flutter test apps/app_user/test/setup_test_data.dart` or
/// `flutter test shared/packages/minglit_seeder` CLI commands instead.
class DevUserSwitchScreen extends ConsumerStatefulWidget {
  /// Creates a dev-only user switch screen.
  const DevUserSwitchScreen({super.key});

  /// Creates the state for the dev user switch screen.
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
            password: 'password1234!',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to $email')),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
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
      body: MinglitAsyncValueWidget(
        value: usersAsync,
        data: (users) {
          if (users.isEmpty) return _buildEmptyState();
          return _buildUserList(users);
        },
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'The database seems empty.\nPlease run the seeder from CLI:\n'
            'flutter test apps/app_user/test/setup_test_data.dart',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
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

        final email = '$username@test.com';

        final (Color? roleColor, String roleLabel) = switch (username) {
          String u when u.startsWith('partner_owner') => (
            Colors.orange[100],
            'Owner',
          ),
          String u when u.startsWith('partner_') => (
            Colors.purple[100],
            'Partner',
          ),
          String u when u.startsWith('staff_') => (Colors.blue[100], 'Staff'),
          _ => (Colors.grey[100], 'User'),
        };

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

/// Fetches test user profiles for the dev user switcher.
@riverpod
Future<List<Map<String, dynamic>>> devUserProfiles(Ref ref) async {
  // Call the dev-session-switch Edge Function via Supabase client
  final supabase = Supabase.instance.client;
  final response = await supabase.functions.invoke('dev-session-switch');

  if (response.status != 200) {
    throw Exception('Failed to fetch users: ${response.status}');
  }

  final body = response.data as Map<String, dynamic>;
  final users = body['users'] as List<dynamic>;
  return users.cast<Map<String, dynamic>>();
}
