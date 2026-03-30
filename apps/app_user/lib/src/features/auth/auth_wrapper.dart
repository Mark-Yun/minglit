import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Auth Wrapper**
///
/// A widget that handles authentication state and displays the appropriate
/// screen. Useful for 'DevMap' or isolated testing.
///
/// Pass [authenticatedChild] to specify the widget shown when logged in.
/// Defaults to a placeholder; caller should provide the actual home widget.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({required this.authenticatedChild, super.key});

  final Widget authenticatedChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MinglitAsyncValueWidget(
      value: authState,
      data: (state) {
        if (state.session != null) {
          return authenticatedChild;
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(body: MinglitCircularProgressIndicator()),
    );
  }
}
