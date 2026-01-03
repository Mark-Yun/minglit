import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: 'Partner Dashboard'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Color(0xFFFF7043)),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  context.l10n.home_welcome_user(user?.email ?? 'Unknown'),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/parties'),
                icon: const Icon(Icons.celebration),
                label: Text(context.l10n.home_button_manageParties),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(context.l10n.home_button_logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
