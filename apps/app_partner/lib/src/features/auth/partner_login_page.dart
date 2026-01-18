import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerLoginPage extends ConsumerWidget {
  const PartnerLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for AuthController errors
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        handleMinglitError(context, next.error, next.stackTrace);
      }
    });

    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: MinglitCircularProgressIndicator());
    }

    return MinglitLoginScreen(
      isPartner: true,
      onGoogleSignIn: () {
        unawaited(ref.read(authControllerProvider.notifier).signInWithGoogle());
      },
    );
  }
}
