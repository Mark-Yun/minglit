import 'dart:async';

import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
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
            defaultRedirectUrl: 'http://localhost:3001',
          ),
        ),
      ],
      child: const MinglitPartnerApp(),
    ),
  );
}

class MinglitPartnerApp extends ConsumerWidget {
  const MinglitPartnerApp({super.key});

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
      title: 'Minglit Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7043),
          primary: const Color(0xFFFF7043),
          secondary: const Color(0xFF1A237E),
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
              return const MinglitSplashScreen(
                appName: 'Partner',
                isPartner: true,
              );
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
          return const PartnerHomePage();
        } else {
          return const PartnerLoginPage();
        }
      },
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

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
        ref.read(authControllerProvider.notifier).signInWithGoogle();
      },
    );
  }
}

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Color(0xFFFF7043)),
            const SizedBox(height: 20),
            Text('사장님(${user?.email ?? 'Unknown'}) 환영합니다!'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}