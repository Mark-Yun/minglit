import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minglit Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.userMetadata?['avatar_url'] != null)
              CircleAvatar(
                backgroundImage: NetworkImage(
                  user!.userMetadata!['avatar_url'] as String,
                ),
                radius: 40,
              ),
            const SizedBox(height: 20),
            Text('안녕하세요, ${user?.userMetadata?['full_name'] ?? user?.email}님!'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed:
                  () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
