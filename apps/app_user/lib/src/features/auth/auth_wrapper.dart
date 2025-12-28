import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Auth Wrapper**
///
/// A widget that handles authentication state and displays the appropriate
/// screen. Useful for 'DevMap' or isolated testing.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      loading:
          () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
    );
  }
}
