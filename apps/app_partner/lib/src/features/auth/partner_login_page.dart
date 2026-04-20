import 'dart:async';

import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerLoginPage extends ConsumerWidget {
  const PartnerLoginPage({
    super.key,
    @visibleForTesting this.isDevEnvOverride,
  });

  // Fix #1624: allows tests to override compile-time ENVIRONMENT constant
  @visibleForTesting
  final bool? isDevEnvOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
    // Fix #1624: 'dev' 추가 — Supabase dev 프로젝트의 ENVIRONMENT=dev와 정합성 유지
    const isDevEnvConst =
        environment == 'local' ||
        environment == 'development' ||
        environment == 'dev';
    final isDevEnv = isDevEnvOverride ?? isDevEnvConst;
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
      // Fix #188: 데브맵 제거 — 5클릭 시 세션 스위처로 직접 이동
      onDevTrigger: isDevEnv
          ? () => const DevUserSwitchRoute().push<void>(context)
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
