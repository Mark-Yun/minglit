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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${next.error}')),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MinglitLoginScreen(
      isPartner: true,
      onGoogleSignIn: () {
        unawaited(ref.read(authControllerProvider.notifier).signInWithGoogle());
      },
    );
  }
}
