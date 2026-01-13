import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

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
        } else {
          // If no 'from' path, let app_router redirect to Home.
          // Or explicitly go home.
          // context.go('/');
        }
      }
    });

    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MinglitLoginScreen(
      onGoogleSignIn: () {
        String? redirectTo;
        if (from != null) {
          final base = Uri.base.origin;
          // Ensure from starts with /
          final path = from!.startsWith('/') ? from : '/$from';
          // Add /# for Hash Routing (Flutter Web Default)
          // If using PathUrlStrategy, remove /#
          redirectTo = '$base/#$path';
          Log.d(
            '🌐 [Auth] Requesting Google Sign-In with redirectTo: $redirectTo',
          );
        }

        unawaited(
          ref
              .read(authControllerProvider.notifier)
              .signInWithGoogle(
                redirectTo: redirectTo,
              ),
        );
      },
    );
  }
}
