import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for AuthController errors
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
      }
    });

    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MinglitLoginScreen(
      onGoogleSignIn: () {
        unawaited(ref.read(authControllerProvider.notifier).signInWithGoogle());
      },
    );
  }
}
