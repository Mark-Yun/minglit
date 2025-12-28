import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);

  runApp(
    ProviderScope(
      overrides: [
        authConfigProvider.overrideWithValue(
          const AuthConfig(
            webClientId: googleWebClientId,
            defaultRedirectUrl: 'http://localhost:3000',
          ),
        ),
      ],
      child: const MinglitApp(),
    ),
  );
}

class MinglitApp extends ConsumerWidget {
  const MinglitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AppView();
  }
}

class _AppView extends ConsumerStatefulWidget {
  const _AppView();

  @override
  ConsumerState<_AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<_AppView> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.notoSansKr(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Minglit User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF7043),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      routerConfig: goRouter,
      builder: (context, child) {
        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const MinglitSplashScreen(appName: 'User');
            }
            return child!;
          },
        );
      },
    );
  }
}

/// A wrapper widget to handle authentication state and display the appropriate screen.
/// Note: With GoRouter redirect logic, this might be less used as a root widget,
/// but still useful for 'DevMap' or isolated testing.
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

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
      onGoogleSignIn: () {
        ref.read(authControllerProvider.notifier).signInWithGoogle();
      },
    );
  }
}

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