import 'dart:async';

import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Color(0xFFFF7043)),
              const SizedBox(height: 20),
              Text('사장님(${user?.email ?? 'Unknown'}) 환영합니다!'),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () => const PartyListRoute().go(context),
                icon: const Icon(Icons.party_mode),
                label: const Text('파티 및 회차 관리'),
              ),
              const SizedBox(height: MinglitSpacing.medium),

              OutlinedButton(
                onPressed: () {
                  unawaited(
                    ref.read(authControllerProvider.notifier).signOut(),
                  );
                },
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
