import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for AuthController changes
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('로그인 실패'),
              content: SelectableText('Error: ${next.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        );
      } else if (next is AsyncData && !next.isLoading) {
        // Login Success
        Log.d('🔑 [Auth] Login Success! from: $from');
        if (from != null) {
          context.go(from!);
        }
      }
    });

    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MinglitLoginScreen(
      onGoogleSignIn: () async {
        // Save return URL to storage to handle redirect after OAuth
        if (from != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_return_url', from!);
          Log.d('💾 [Auth] Saved return URL: $from');
        }

        if (context.mounted) {
          unawaited(
            ref.read(authControllerProvider.notifier).signInWithGoogle(
                  // No redirectTo needed; we rely on storage redirect
                  redirectTo: null,
                ),
          );
        }
      },
    );
  }
}
