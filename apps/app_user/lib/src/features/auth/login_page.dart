import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for AuthController error state only.
    // Navigation is handled by GoRouter's refreshListenable + redirect.
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        handleMinglitError(context, next.error, next.stackTrace);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isAppleSignInAvailable =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (authState.isLoading) {
      return const Scaffold(body: MinglitCircularProgressIndicator());
    }

    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
    const isDevEnv = environment == 'local' || environment == 'development';

    // When redirected from a protected route (from != null),
    // back key should return to home instead of closing the app.
    return PopScope(
      canPop: from == null,
      onPopInvokedWithResult: (didPop, _) {
        // Fix #404: Use coordinator instead of direct GoRouter access
        if (!didPop && context.mounted) {
          ref.read(authCoordinatorProvider).goToHome();
        }
      },
      child: MinglitLoginScreen(
        onGoogleSignIn: () async {
          // Save return URL to storage to handle redirect after OAuth
          if (from != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_return_url', from!);
            Log.d('💾 [Auth] Saved return URL: $from');
          }

          if (context.mounted) {
            String? redirectTo;
            if (kIsWeb) {
              final origin = Uri.base.origin;
              redirectTo = '$origin/#/auth/callback';
              Log.d('🌐 [Auth] RedirectTo set: $redirectTo');
            }

            unawaited(
              ref
                  .read(authControllerProvider.notifier)
                  .signInWithGoogle(
                    redirectTo: redirectTo,
                  ),
            );
          }
        },
        onAppleSignIn: isAppleSignInAvailable
            ? () async {
                if (from != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('auth_return_url', from!);
                  Log.d('💾 [Auth] Saved return URL: $from');
                }

                if (context.mounted) {
                  String? redirectTo;
                  if (kIsWeb) {
                    final origin = Uri.base.origin;
                    redirectTo = '$origin/#/auth/callback';
                    Log.d('🌐 [Auth] Apple redirectTo set: $redirectTo');
                  }

                  unawaited(
                    ref
                        .read(authControllerProvider.notifier)
                        .signInWithApple(
                          redirectTo: redirectTo,
                        ),
                  );
                }
              }
            : null,
        onKakaoSignIn: () async {
          if (from != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_return_url', from!);
            Log.d('💾 [Auth] Saved return URL: $from');
          }

          if (context.mounted) {
            String? redirectTo;
            if (kIsWeb) {
              final origin = Uri.base.origin;
              redirectTo = '$origin/#/auth/callback';
              Log.d('🌐 [Auth] Kakao redirectTo set: $redirectTo');
            }

            unawaited(
              ref
                  .read(authControllerProvider.notifier)
                  .signInWithKakao(
                    redirectTo: redirectTo,
                  ),
            );
          }
        },
        // Fix #188: 데브맵 제거 — 5클릭 시 세션 스위처로 직접 이동
        // Fix #404: Use coordinator instead of direct route push
        onDevTrigger: isDevEnv
            ? () => ref.read(authCoordinatorProvider).pushDevUserSwitch()
            : null,
      ),
    );
  }
}
