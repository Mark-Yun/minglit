import 'dart:async';

import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerLoginPage extends ConsumerWidget {
  const PartnerLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
    const isDevEnv = environment == 'local' || environment == 'development';
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

    return MinglitLoginScreen(
      isPartner: true,
      onDevMapTrigger: isDevEnv
          ? () => const DevMapRoute().push(context)
          : null,
      onGoogleSignIn: () {
        unawaited(ref.read(authControllerProvider.notifier).signInWithGoogle());
      },
      onAppleSignIn: isAppleSignInAvailable
          ? () {
              unawaited(
                ref.read(authControllerProvider.notifier).signInWithApple(),
              );
            }
          : null,
      onKakaoSignIn: () {
        unawaited(
          ref.read(authControllerProvider.notifier).signInWithKakao(),
        );
      },
    );
  }
}
