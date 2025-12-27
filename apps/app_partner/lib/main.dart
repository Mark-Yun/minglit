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
  setupLocator(
    googleWebClientId: googleWebClientId,
    defaultRedirectUrl: 'http://localhost:3001',
  );

  runApp(const MinglitPartnerApp());
}

class MinglitPartnerApp extends StatelessWidget {
  const MinglitPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: locator<AuthRepository>()),
        RepositoryProvider.value(value: locator<PartnerRepository>()),
        RepositoryProvider.value(value: locator<VerificationRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create:
                (context) => PartnerBloc(
                  partnerRepository: context.read<PartnerRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => VerificationBloc(
                  verificationRepository:
                      context.read<VerificationRepository>(),
                ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  Future<void> _initialize() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.notoSansKr(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MinglitSplashScreen(
              appName: 'Partner',
              isPartner: true,
            );
          }
          return const AuthWrapper();
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return state.maybeWhen(
          authenticated: (_) => const PartnerHomePage(),
          loading:
              () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
          orElse: () => const PartnerLoginPage(),
        );
      },
    );
  }
}

class PartnerLoginPage extends StatelessWidget {
  const PartnerLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          failure: (message) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Login Failed: $message')));
          },
        );
      },
      child: MinglitLoginScreen(
        isPartner: true,
        onGoogleSignIn: () {
          context.read<AuthBloc>().add(const AuthEvent.signInWithGoogle());
        },
      ),
    );
  }
}

class PartnerHomePage extends StatelessWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select(
      (AuthBloc bloc) =>
          bloc.state.maybeWhen(authenticated: (u) => u, orElse: () => null),
    );

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
                context.read<AuthBloc>().add(const AuthEvent.signOut());
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
