import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
  const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  setupLocator(googleWebClientId: googleWebClientId, defaultRedirectUrl: 'http://localhost:3000');

  runApp(const MinglitApp());
}

class MinglitApp extends StatelessWidget {
  const MinglitApp({super.key});

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
            create: (context) => AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => PartnerBloc(partnerRepository: context.read<PartnerRepository>()),
          ),
          BlocProvider(
            create: (context) => VerificationBloc(verificationRepository: context.read<VerificationRepository>()),
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
      home: FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MinglitSplashScreen(appName: 'User');
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
          authenticated: (_) => const HomePage(),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          orElse: () => const LoginPage(),
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          failure: (message) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그인 실패'),
                content: SelectableText('Error: $message'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
              ),
            );
          },
        );
      },
      child: MinglitLoginScreen(
        isPartner: false,
        onGoogleSignIn: () {
          context.read<AuthBloc>().add(const AuthEvent.signInWithGoogle());
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => 
      bloc.state.maybeWhen(authenticated: (u) => u, orElse: () => null)
    );
    
    return Scaffold(
      appBar: AppBar(title: const Text('Minglit Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.userMetadata?['avatar_url'] != null)
              CircleAvatar(backgroundImage: NetworkImage(user!.userMetadata!['avatar_url']), radius: 40),
            const SizedBox(height: 20),
            Text('안녕하세요, ${user?.userMetadata?['full_name'] ?? user?.email}님!'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(const AuthEvent.signOut()), 
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
